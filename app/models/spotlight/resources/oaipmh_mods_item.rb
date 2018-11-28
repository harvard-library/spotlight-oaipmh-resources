require 'oai'
require 'mods'
#require 'carrierwave'

include OAI::XPath
include Spotlight::Resources::Exceptions
module Spotlight::Resources
  class OaipmhModsItem
    attr_reader :titles, :id
    attr_accessor :metadata, :sidecar_data
    def initialize(exhibit, converter, cna_config)
      @solr_hash = {}
      @exhibit = exhibit
      @converter = converter
      @catalog_url = nil
      @finding_aid_url = nil
      @creator = nil
      @repository = nil
      @cna_config = cna_config
    end
    
    def to_solr
      add_document_id
      solr_hash
    end
    
    def parse_mods_record()
        
      @modsrecord = Mods::Record.new.from_str(metadata.elements.to_a[0].to_s)
          
      if (@modsrecord.mods_ng_xml.record_info && @modsrecord.mods_ng_xml.record_info.recordIdentifier)
        @id = @modsrecord.mods_ng_xml.record_info.recordIdentifier.text 
        #Strip out all of the decimals
        @id = @id.gsub('.', '')
      end
      
      begin
        @titles = @modsrecord.full_titles
      rescue NoMethodError
        @titles = nil
      end
      
      if (@titles.blank? && @id.blank?)
        raise InvalidModsRecord, "A mods record was found that has no title and no identifier."
      elsif (@titles.blank?)
        raise InvalidModsRecord, "Mods record " + @id + " must have a title.  This mods record was not updated in Spotlight."
      elsif (@id.blank?)
        raise InvalidModsRecord, "Mods record " + @titles[0] + "must have a title. This mods record was not updated in Spotlight."
      end  
      
      @solr_hash = @converter.convert(@modsrecord)
      @sidecar_data = @converter.sidecar_hash
   end
   
   #This pulls the catalog url from the Mods::Record item for OASIS items.  Using the Mods::Record paths fail for this
   #I suspect that the way the mods gem is written conflicts with the way we have our paths (relatedItem/relatedItem/relatedItem/location/url)
   def get_catalog_url()
     if (@catalog_url.nil?)
       node = @modsrecord.mods_ng_xml.xpath(@cna_config['HOLLIS_RECORD_XPATH'])
       if (!node.blank?)
         @catalog_url = node.text
       else
         @catalog_url = ""
       end   
     end
     @catalog_url
   end
   
  #This pulls the finding aid url from the Mods::Record item for OASIS items.  Using the Mods::Record paths fail for this
  #I suspect that the way the mods gem is written conflicts with the way we have our paths (relatedItem/relatedItem/relatedItem/location/url)
  def get_finding_aid()
     if (@finding_aid_url.nil?)
       node = @modsrecord.mods_ng_xml.xpath(@cna_config['FINDING_AID_XPATH'])
       if (!node.blank?)
         @finding_aid_url = node.text
       else
         @finding_aid_url = ""
       end
     end
     @finding_aid_url
   end

  #This pulls the creator from the Mods::Record item for OASIS items.  Using the Mods::Record paths fail for this
  #I suspect that the way the mods gem is written conflicts with the way we have our paths (relatedItem/relatedItem/relatedItem/name/namePart)
  def get_creator()
     if (@creator.nil?)
       node = @modsrecord.mods_ng_xml.related_item.xpath(@cna_config['CREATOR_XPATH'])
       if (!node.blank?)
         node.role.roleTerm.each do |roleTerm|
           if (roleTerm.text.eql?('creator'))
             @creator = node.namePart.text
           end
         end
       else
         @creator = ""
       end
     end
     @creator
   end

  #This pulls the repository from the Mods::Record item for OASIS items.  Using the Mods::Record paths fail for this
  #I suspect that the way the mods gem is written conflicts with the way we have our paths (nested related items)
  def get_repository()
     if (@repository.nil?)
       node = @modsrecord.mods_ng_xml.related_item.xpath(@cna_config['REPOSITORY_XPATH'])
       if (!node.blank?)
         @repository = node.text
       else
         @repository = ""
       end
     end
     @repository
   end
   
   #This pulls the collection title from the Mods::Record item for OASIS items.  Using the Mods::Record paths fail for this
  #I suspect that the way the mods gem is written conflicts with the way we have our paths (nested related items)
  def get_collection_title()
     if (@collectiontitle.nil?)
       titlenode = @modsrecord.mods_ng_xml.xpath(@cna_config['COLLECTION_TITLE_XPATH'])
       datenode = @modsrecord.mods_ng_xml.xpath(@cna_config['COLLECTION_TITLE_DATE_XPATH'])
       if (!titlenode.blank? && !datenode.blank?)
         @collectiontitle = titlenode.text + " " + datenode.text
       elsif (!titlenode.blank?)
         @collectiontitle = titlenode.text
       else
         @collectiontitle = ""
       end
     end
     @collectiontitle
   end
    
   # private
    
    attr_reader :solr_hash, :exhibit
    
    
    
    def add_document_id
      solr_hash[:id] = @id.to_s
    end
  
  end
end