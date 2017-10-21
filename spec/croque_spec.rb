require "spec_helper"

RSpec.describe Croque do
  it "has a version number" do
    expect(Croque::VERSION).not_to be nil
  end

  # Croque was born in 2017-10-21
  let(:date) { Date.new(2017, 10, 21) }

  it "Run Croque.aggregate, then generate Ranking" do
    # Do aggregate
    Croque.aggregate(date)
    # generate?
    ranking_path = Croque.config.store_path.join("#{date}", "ranking.csv")
    expect(File.exist?(ranking_path)).to eq(true)
  end

  it "Get Ranking" do
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
end
