module Croque
  class Monsieur

    attr_accessor :date, :hour, :id, :time, :line

    def initialize(date, hour, id, time)
      self.date = Date.parse(date)
      self.hour = hour.to_i
      self.id = id
      self.time = time
    end

    def body
      # return Array
      lines = get_line[7].split("\t")
      lines = lines.map{ |line| line.strip }
      lines.each do |line|
        print "#{line}\n"
      end
      lines = lines.map{ |line| line.gsub(/\e\[\d+m/, '') }
      lines
    end

    def views_time
      get_line[2].to_f
    end

    def active_record_time
      get_line[3].to_f
    end

    def processing_time
      self.time.to_f
    end

    def full_path
      URI.unescape(get_line[4])
    end

    def path_info
      get_line[5]
    end

    def query
      URI.unescape(get_line[6])
    end

    class << self
      def get_list(date, limit)
        csv_data = File.open(ranking_path(date), "r").read.gsub(/\r/, "")
        csv = CSV.new(csv_data)
        # Sorted lines as ranking
        csv.to_a[0..(limit-1)].map do |line|
          # line = [date, hour, uuid, processing_time (ms)]
          self.new(*line)
        end
      end

      private
      def ranking_path(date)
        Croque.config.store_path.join("#{date}", "ranking.csv")
      end
    end

    private
    def get_line
      self.line ||= if File.exist?(csv_path)
        csv_data = File.open(csv_path, "r").read.gsub(/\r/, "")
        csv = CSV.new(csv_data)
        csv.to_a.find{ |line| line[0] == self.id }
      else
        nil
      end
    end

    def csv_path
      Croque.config.store_path.join("#{self.date}", "#{self.hour}.csv")
    end
  end
end
