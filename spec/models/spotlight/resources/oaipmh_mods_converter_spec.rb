require 'spec_helper'
require 'yaml'
require 'oai'
require 'nokogiri'
require 'xml/libxml'

include OAI::XPath
            

  RSpec.describe Spotlight::Resources::OaipmhModsConverter, type: :model do
    subject { described_class.new('CNA', 'test-exhibit-name', file_fixture("mapping_sample.yml")) }
    let(:abc_set) {described_class.new('ABC', 'test-exhibit-name')}
      
      describe 'mapping_config_file_exists' do
        context 'given a set name' do
          it 'verifies that the mapping file exists' do
            mapping_file = subject.mapping_file
            #expect(File.basename(mapping_file)).to eq('mapping.yml')
            print mapping_file + "\n"
            expect(File.basename(mapping_file)).to match(/mapping_sample.yml/i)
          end
        end
      end
      
      describe 'mapping sample' do
        context 'given a set name' do
          it 'verifies that the expected fields exist' do
            fixture_mapping_file = file_fixture("mapping_sample.yml")
            mapping_config = YAML.load_file(fixture_mapping_file)
            subject.parse_mapping_file(fixture_mapping_file)
                        
            require 'xml/libxml'
            fixture_mods_file = file_fixture("mods_sample.xml")
            
            doc = LibXML::XML::Document.file(fixture_mods_file.to_s)
            modsonly = xpath_first(doc, "//*[local-name()='mods']")
            modsrecord = Mods::Record.new.from_str(modsonly.to_s)

            solr_hash = subject.convert(modsrecord)
            expect(solr_hash['unique-id_tesim']).to eq("007139874")
            #expect(solr_hash['record-type_ssim']).to eq("collection")
            expect(solr_hash['full_title_tesim']).to eq("Mr. Webster's Dudleian lecture on Presbyterian ordination: lecture [delivered], Sept. 7, 1774")
            #expect(solr_hash['citation-title_tesim']).to eq("Mr. Webster's Dudleian lecture on Presbyterian ordination: lecture [delivered], Sept. 7, 1774")
            expect(solr_hash['exhibit_test-exhibit-name_creator_tesim']).to eq("Webster, Samuel , 1718-1796")
            expect(solr_hash['exhibit_test-exhibit-name_start-date_tesim']).to eq("1774mau")
            expect(solr_hash['exhibit_test-exhibit-name_end-date_tesim']).to be_nil
            expect(solr_hash['exhibit_test-exhibit-name_date_tesim']).to eq("1774")
            expect(solr_hash['exhibit_test-exhibit-name_contributer_tesim']).to be_nil
#            expect(solr_hash['spotlight_upload_description_tesim']).to eq("The hand-sewn notebook contains a manuscript draft of the Dudleian
#            lecture delivered by Samuel Webster on September 7, 1774 at Harvard College. The sermon
#            begins with the Biblical text Matt. 20:25-28. The copy includes a small number of edits
#            and struck-out words. The item is missing the back cover and appears to be missing its
#            final pages.|Received March 8, 1843 from President Quincy.")
            expect(solr_hash['exhibit_test-exhibit-name_format_tesim']).to eq(".03 cubic feet (1 volume)|p. 20 x 16 cm.")
            expect(solr_hash['exhibit_test-exhibit-name_language_ssim']).to eq("eng")
            expect(solr_hash['exhibit_test-exhibit-name_repository_ssim']).to eq("Harvard University Archives")
            expect(solr_hash['exhibit_test-exhibit-name_subjects_ssim']).to eq("Presbyterianism|Harvard College (1636-1780)--Sermons|Ordination--Early works to 1800")
            expect(solr_hash['exhibit_test-exhibit-name_type_ssim']).to eq("Sermons-1774., Lectures-Massachusetts-Cambridge-1774.")
            expect(solr_hash['exhibit_test-exhibit-name_origin_ssim']).to eq("mau")
#            expect(solr_hash['exhibit_test-exhibit-name_biography_tesim']).to eq('Samuel Webster (1718-1796), minister of Second Church of the West Parish
#            of Salisbury, Mass., was born on August 16, 1718 in Bradford, Mass. He received an AB
#            from Harvard in 1737 and an AM in 1740. He was ordained as a minister of the Rocky Hill
#            meetinghouse of the West Parish of Salisbury on August 12, 1741. In 1777 he delivered
#            the Election Sermon to the Massachusetts General Court. He received a doctorate in
#            sacred theology from Harvard in 1792. Webster died on July 18, 1796.|Harvard\'s oldest endowed lecture, the annual Dudleian
#            lecture, is funded by a bequest from the 1750 will of the Chief Justice of Massachusetts
#            Paul Dudley (1675-1750/1). Dudley specified that the topics of the annual sermon were to
#            rotate among four themes: natural religion, revealed religion, the "Romish church," and
#            the validity of the ordination of ministers. The first lecture was given in 1755, and
#            the series continued uninterrupted until 1857, when the fund was suspended to allow for
#            accumulation. The lecture series began again in 1888. In 1911, the Trustees voted to
#            discontinue the third lecture topic, and the series continued rotating among the three
#            topics until 1956, when another lecture topic, "Catholicism and Protestantism," was
#            voted into the rotation.')
            expect(solr_hash['exhibit_test-exhibit-name_statement-of-responsibility_tesim']).to be_nil
            expect(solr_hash['exhibit_test-exhibit-name_physical-form_tesim']).to be_nil
            expect(solr_hash['exhibit_test-exhibit-name_language-info_tesim']).to be_nil
            expect(solr_hash['exhibit_test-exhibit-name_publications_tesim']).to be_nil
          end
        end
      end
      
      
      describe 'xpath mapping sample single item' do
        context 'given an xpath in the mapping file' do
          it 'verifies that the xpath exists and is populated properly' do
            fixture_mapping_file = file_fixture("mapping_sample_with_xpath.yml")
            mapping_config = YAML.load_file(fixture_mapping_file)
            subject.parse_mapping_file(fixture_mapping_file)
            
            fixture_mods_file = file_fixture("mods_sample_item.xml")
            
            doc = LibXML::XML::Document.file(fixture_mods_file.to_s)
            modsonly = xpath_first(doc, "//*[local-name()='mods']")
            modsrecord = Mods::Record.new.from_str(modsonly.to_s)
            
            solr_hash = subject.convert(modsrecord)
            expect(solr_hash['exhibit_test-exhibit-name_xpath-test_ssim']).to eq("Houghton Library, Harvard Library, Harvard University")
            expect(solr_hash['exhibit_test-exhibit-name_xpath-test-harvard-namespace_ssim']).to eq("FHCL.HOUGH")
          end
        end
      end 
     
     
      describe 'parse mapping file' do
        context 'given a mapping file' do
          it 'verifies that no exception is thrown and that the converter_items has been populated' do
            fixture_mapping_file = file_fixture("mapping_sample.yml")
            expect {subject.parse_mapping_file(fixture_mapping_file) }.not_to raise_error 
            items = subject.parse_mapping_file(fixture_mapping_file)
            expect(items).not_to be_empty
          end
        end
      end
      
      describe 'mapping missing path value' do
        context 'given a mapping file missing a path value' do
          it 'verifies that an exception is thrown' do
            fixture_mapping_file = file_fixture("mapping_missing_path_value.yml")
            expect {subject.parse_mapping_file(fixture_mapping_file) }.to raise_error(Spotlight::Resources::Exceptions::InvalidMappingFile)  
          end
        end
      end
 
    describe 'mapping missing path' do
      context 'given a mapping file missing a mods path' do
        it 'verifies that an exception is thrown' do
          fixture_mapping_file = file_fixture("mapping_missing_path.yml")
          expect {subject.parse_mapping_file(fixture_mapping_file) }.to raise_error(Spotlight::Resources::Exceptions::InvalidMappingFile)  
        end
      end
    end

    describe 'mapping missing spotlight field value' do
      context 'given a mapping file missing a spotlight field value' do
        it 'verifies that an exception is thrown' do
          fixture_mapping_file = file_fixture("mapping_missing_spotlight_field_value.yml")
          expect {subject.parse_mapping_file(fixture_mapping_file) }.to raise_error(Spotlight::Resources::Exceptions::InvalidMappingFile)  
        end
      end
    end  
 
    describe 'mapping missing spotlight field' do
      context 'given a mapping file missing a spotlight field' do
        it 'verifies that an exception is thrown' do
          fixture_mapping_file = file_fixture("mapping_missing_spotlight_field.yml")
          expect {subject.parse_mapping_file(fixture_mapping_file) }.to raise_error(Spotlight::Resources::Exceptions::InvalidMappingFile)  
        end
      end
    end 
  
    
      
  end

