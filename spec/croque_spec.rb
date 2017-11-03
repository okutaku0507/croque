require "spec_helper"

RSpec.describe Croque do
  it "has a version number" do
    expect(Croque::VERSION).not_to be nil
  end

  # Croque was born in 2017-10-21
  let(:date) { Date.new(2017, 10, 21) }

  it "aggregate, then generate ranking" do
    # Do aggregate
    Croque.aggregate(date)
    # generate?
    ranking_path = Croque.config.store_path.join("#{date}", "ranking.csv")
    expect(File.exist?(ranking_path)).to eq(true)
  end

  it "Get ranking" do
    # Do aggregate
    Croque.aggregate(date)
    # get Ranking as Array
    ranking = Croque.ranking(date)
    # ranking is Array?
    expect(ranking.kind_of?(Array)).to eq(true)
    # monsieur is a ranking object
    monsieur = ranking[0]
    expect(monsieur).not_to eq(nil)
    expect(monsieur.processing_time).not_to eq(nil)
    expect(monsieur.full_path).not_to eq(nil)
  end

  it "Get ranking with paging" do
    # Do aggregate
    Croque.aggregate(date)
    # get first page
    first_page = Croque.ranking(date, page: 1, per: 1)
    # get second page
    second_page = Croque.ranking(date, page: 2, per: 1)
    # get combined page
    combined_page = Croque.ranking(date, per: 2)
    # first_page + second_page => combined_page
    ids = (first_page + second_page).map(&:id)
    combined_ids = combined_page.map(&:id)
    expect(ids).to eq(combined_ids)
  end

  it "Get all" do
    # Do aggregate
    Croque.aggregate(date)
    # Get all
    dates = Croque.all
    expect(dates.kind_of?(Array)).to eq(true)
    expect(dates.include?(date)).to eq(true)
  end

  it "Get total count" do
    # Do aggregate
    Croque.aggregate(date)
    # Get all
    total_count = Croque.total_count(date)
    expect(total_count).not_to eq(nil)
    expect(0 < total_count).to eq(true)
  end
end
