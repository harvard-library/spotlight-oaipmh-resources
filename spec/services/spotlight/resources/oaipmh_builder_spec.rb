require 'spec_helper'
RSpec.describe Spotlight::Resources::OaipmhBuilder do
  let(:exhibit) { FactoryBot.create(:exhibit) }
  let(:doc_builder) { described_class.new(resource) }
  let(:resource) { Spotlight::Resources::OaipmhHarvester.new(exhibit_id: exhibit.id, data: {base_url: 'http://api-qa.lib.harvard.edu:8080/oai', set: 'CNA'}) }

  describe 'calculate_ranges_logic' do
       context 'given a start and end date' do
         it 'verifies the year range' do
           range1 = doc_builder.calculate_ranges(1500, 1650)
           expect(range1).to eq("pre-1600|1600-1609|1610-1619|1620-1629|1630-1639|1640-1649|1650-1659")
           
           range2 = doc_builder.calculate_ranges(1500, 1649)
           expect(range2).to eq("pre-1600|1600-1609|1610-1619|1620-1629|1630-1639|1640-1649")
           
           range3 = doc_builder.calculate_ranges(1500, 1643)
           expect(range3).to eq("pre-1600|1600-1609|1610-1619|1620-1629|1630-1639|1640-1649")

           range4 = doc_builder.calculate_ranges(1600, 1643)
           expect(range4).to eq("1600-1609|1610-1619|1620-1629|1630-1639|1640-1649")

           range5 = doc_builder.calculate_ranges(1603, 1643)
           expect(range5).to eq("1600-1609|1610-1619|1620-1629|1630-1639|1640-1649")
           
           range6 = doc_builder.calculate_ranges(1609, 1643)
           expect(range6).to eq("1600-1609|1610-1619|1620-1629|1630-1639|1640-1649")
           
           range7 = doc_builder.calculate_ranges(1610, 1643)
           expect(range7).to eq("1610-1619|1620-1629|1630-1639|1640-1649")
           
           range8 = doc_builder.calculate_ranges(1751, 1800)
           expect(range8).to eq("1750-1759|1760-1769|1770-1779|1780-1789|1790-1799|1800-present")
 
           range9 = doc_builder.calculate_ranges(1751, 1799)
           expect(range9).to eq("1750-1759|1760-1769|1770-1779|1780-1789|1790-1799")

           range10 = doc_builder.calculate_ranges(1751, 1850)
           expect(range10).to eq("1750-1759|1760-1769|1770-1779|1780-1789|1790-1799|1800-present")
                             
         end
       end
     end
end
