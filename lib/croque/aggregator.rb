module Croque
  module Aggregator
    class << self
      def aggregate(date)
        # remove files
        remove_files(date)
        # aggregate per hour
        aggregate_per_hour(date)
        # generate_ranking
        generate_ranking(date)
      end

      def aggregate_per_hour(date)
        # scan each file
        log("aggregate logs per hour on #{date} start")
        log_files.each do |file|
          log("check skippable of #{file}")
          # check skippable
          next if skippable?(date, file)
          log("aggregate logs of #{file}")
          # all lines
          linage = 1000
          wc_result = `wc -l #{file}`
          line_count = wc_result.match(/\d+/)[0].to_i
          k = 1
          lines = []
          # extract the matched line (Date)
          while (k-1)*linage < line_count
            log("aggregate logs for #{(k-1)*linage}-#{k*linage} in #{line_count} on #{date}")
            fragment = `head -n #{k*1000} #{file} | tail -n #{linage}`
            fragment_lines = fragment.lines
            lines += fragment_lines.select do |line|
              line.match(date_matcher(date))
            end
            k += 1
          end
          hours.each do |hour|
            # craete csv file
            log("create csv for #{date} #{hour} hour")
            create_csv(date, hour, lines)
          end
        end
        log("aggregate logs per hour on #{date} end")
      end

      def generate_ranking(date)
        log("generate ranking on #{date} start")
        array = []
        hours.each do |hour|
          log("generate array for ranking in #{date} #{hour} hour")
          # csv data
          path = csv_path(date, hour)
          # next if no file
          next unless File.exist?(path)
          csv_data = File.open(path, "r").read.gsub(/\r/, "")
          csv = CSV.new(csv_data)
          csv.to_a.each do |line|
            uuid = line[0]
            processing_time = line[1].to_f
            next if low?(processing_time)
            array << [date, hour, uuid, processing_time]
          end
        end
        log("sort array for ranking on #{date}")
        # Processing Time Desc
        array = array.sort{ |a, b| b[3] <=> a[3] }
        log("generate ranking csv on #{date}")
        # Generate CSV
        data = CSV.generate("", csv_option) do |csv|
          array.each{ |line| csv << line }
        end
        store_csv(ranking_path(date), data)
        log("generate ranking on #{date} end")
      end

      def all
        paths = Dir.glob(store_path + '*')
        paths = paths.select do |path|
          path.match(/\d{4}\-\d{2}\-\d{2}/)
        end
        paths.map do |path|
          Date.parse(File.basename(path))
        end
      end

      private
      def log_files
        Dir::glob(dir_path + '*').select do |path|
          path.match(log_file_matcher)
        end
      end

      def dir_path
        Croque.config.log_dir_path
      end

      def store_path
        Croque.config.store_path
      end

      def ranking_path(date)
        store_path.join("#{date}", "ranking.csv")
      end

      def log_file_matcher
        Croque.config.log_file_matcher
      end

      def remove_files(date)
        path = store_path.join("#{date}")
        if Dir.exist?(path)
          FileUtils.remove_dir(path)
        end
      end

      def skippable?(date, file)
        # matcher
        matcher = convert_matcher(matcher: Croque.config.matcher)
        # head
        head_lines = `head -n 100 #{file}`
        # get lines as Array
        head_lines = head_lines.lines
        head_line = head_lines.select do |line|
          line.match(matcher)
        end.first
        head_date = get_date_from_line(head_line)
        # tail
        tail_lines = `tail -n 100 #{file}`
        # get lines as Array
        tail_lines = tail_lines.lines
        tail_line = tail_lines.select do |line|
          line.match(matcher)
        end.last
        tail_date = get_date_from_line(tail_line)
        # include date during range
        return !(head_date && tail_date && (head_date..tail_date).include?(date))
      end

      def get_date_from_line(line)
        if line.present?
          match = line.match(/\d{4}\-\d{2}\-\d{2}/)
          if match
            begin
              Date.parse(match[0])
            rescue
              nil
            end
          end
        end
      end

      def date_matcher(date)
        convert_matcher(
          matcher: Croque.config.matcher,
          date: date
        )
      end

      def hour_matcher(hour)
        convert_matcher(
          matcher: Croque.config.hour_matcher,
          hour: hour
        )
      end

      def severity_matcher(date, severity)
        convert_matcher(
          matcher: Croque.config.matcher,
          severity: severity
        )
      end

      def start_matcher
        Croque.config.start_matcher
      end

      def end_matcher
        Croque.config.end_matcher
      end

      def except_path_matcher
        Croque.config.except_path_matcher
      end

      def convert_matcher(matcher:, date: nil, hour: nil, severity: nil)
        # Regexp => String
        matcher = matcher.source
        # date => XXXX-XX-XX
        date = if date
          date.to_s
        else
          "\\d{4}-\\d{2}-\\d{2}"
        end.gsub(/\-/, "\\-")
        # hour = format("%02d", hour)
        hour = if hour
          format("%02d", hour)
        else
          "\\d{2}"
        end
        severity = if severity
          severity
        else
          "#\\d+"
        end
        # replace particular string
        matcher = matcher.gsub(/severity/, severity)
        matcher = matcher.gsub(/hour/, hour)
        matcher = matcher.gsub(/date/, date)
        # String => Regexp
        Regexp.new(matcher)
      end

      def hours
        (0..23).to_a
      end

      def csv_path(date, hour)
        store_path.join("#{date}", "#{hour}.csv")
      end

      def csv_option
        {
          row_sep: "\r\n",
          headers: false,
          write_headers: true,
          force_quotes: true
        }
      end

      def headers
        [
          "Line ID", # 0
          "Processing Time (ms)", # 1
          "Views Time (ms)", # 2
          "ActiveRecord Time (ms)", # 3
          "Full Path", # 4
          "Path Info", # 5
          "Params", # 6
          "Body" # 7
        ]
      end

      def create_csv(date, hour, lines)
        # extract the matched line (Hour)
        path = csv_path(date, hour)
        lines_per_hour = lines.select{ |line| line.match(hour_matcher(hour)) }
        # get start line of request
        start_indexes = get_start_indexes(lines_per_hour)
        data = CSV.generate("", csv_option) do |csv|
          start_indexes.each do |start_index|
            values = []
            start_line = lines_per_hour[start_index]
            severity = get_severity(start_line)
            end_index = get_end_index(date, severity, start_index, lines_per_hour)
            if end_index
              # Line ID
              values << SecureRandom.uuid
              # get End Line
              end_line = lines_per_hour[end_index]
              # Processing Time
              values << get_processing_time(end_line)
              # Views Time
              values << get_views_time(end_line)
              # ActiveRecord Time
              values << get_active_record_time(end_line)
              # Full path
              full_path = get_full_path(start_line)
              values << full_path
              # Path Info
              values << get_path_info(full_path)
              # Params
              values << get_params(full_path)
              # Body
              lines_per_severity = get_lines_per_severity(date, start_index, end_index, severity, lines_per_hour)
              values << lines_per_severity.join("\t")
              # values to CSV
              csv << values
            end
          end
        end
        store_csv(path, data)
      end

      def store_csv(path, data)
        # make dirctroy
        unless Dir.exist?(File.dirname(path))
          FileUtils.mkdir_p(File.dirname(path))
        end
        File.open(path, 'a') do |f|
          f.write data
        end
      end

      def get_start_indexes(lines)
        # map index only matched line
        lines.map.with_index do |line, index|
          index if line.match(start_matcher) && !line.match(except_path_matcher)
        end.compact
      end

      def get_severity(line)
        line.match(/#\d+/)[0]
      end

      def get_end_index(date, severity, start_index, lines)
        # end line = first of matched lines
        lines.map.with_index do |line, index|
          index if start_index < index && line.match(end_matcher) &&
            line.match(severity_matcher(date, severity))
        end.compact.first
      end

      def get_lines_per_severity(date, start_index, end_index, severity, lines)
        lines[start_index..end_index].select do |line|
          line.match(severity_matcher(date, severity))
        end
      end

      def get_processing_time(line)
        match = line.match(/([1-9]\d*|0)(\.\d+)?ms/)
        if match
          match[0].match(/([1-9]\d*|0)(\.\d+)?/)[0].to_f.round(1)
        else
          0
        end
      end

      def get_views_time(line)
        match = line.match(/Views: ([1-9]\d*|0)(\.\d+)?ms/)
        if match
          match[0].match(/([1-9]\d*|0)(\.\d+)?/)[0].to_f.round(1)
        else
          0
        end
      end

      def get_active_record_time(line)
        match = line.match(/ActiveRecord: ([1-9]\d*|0)(\.\d+)?ms/)
        if match
          match[0].match(/([1-9]\d*|0)(\.\d+)?/)[0].to_f.round(1)
        else
          0
        end
      end

      def get_full_path(line)
        line.match(/\".*\"/)[0].gsub(/\"/, '')
      end

      def get_path_info(full_path)
        URI.parse("http://example.com#{full_path}").path
      end

      def get_params(full_path)
        URI.parse("http://example.com#{full_path}").query
      end

      def low?(time)
        time < Croque.config.lower_time
      end

      def log(message)
        Croque.config.logger.try(:info, message)
      end
    end
  end
end
