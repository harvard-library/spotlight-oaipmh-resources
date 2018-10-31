include Spotlight::Resources::Exceptions
module Spotlight::Resources
  

  class ModsPath
    attr_accessor :path, :subpaths, :delimiter
  end
  class ModsItem
    attr_accessor :mods_path, :mods_attribute, :mods_attribute_value, :conditional_mods_value, :conditional_mods_path
  end
  class ConverterItem
    attr_accessor :spotlight_field, :mods_items, :default_value, :delimiter, :xpath_string, :xpath_namespace_def, :xpath_namespace_prefix
    
    RESERVED_WORDS = {'name'=> "name_el", 'description' => 'description_el', 'type' => 'type_at'}
    TOP_LEVEL_ELEMENTS_SIMPLE = [
        'abstract',
        'accessCondition',
        'classification',
        'extension',
        'genre',
        'identifier',
        'note',
        'tableOfContents',
        'targetAudience',
        'typeOfResource',
        ]
        
    def initialize()
      delimiter = ", "
    end
    
    def extract_value(modsrecord)
      values = Array.new
              
      mods_items.each do |item|
        #Throw error if path value fails
        begin
          node = modsrecord.mods_ng_xml
          
          retvalues = parse_paths(item, node)
          if (retvalues.empty? && !default_value.blank?)
            value = default_value
            values << value
          elsif (!retvalues.empty?)
            value = retvalues.join(delimiter)
            values << value
          end
          
        rescue NoMethodError => e
          puts e.message
          puts e.backtrace
          puts  "The path " + item.mods_path.path + " does not exist\n"
        end
      
      end
      if (!values.empty?)
        values.join(delimiter) 
      end
    end

    
    #Creates the proper path and subpath names to use since some words may be reserved.
    #It then uses these paths to search for the value in the Mods::Record
    def parse_paths(item, parentnode)
      path_array = item.mods_path.path.split("/")
      if (!TOP_LEVEL_ELEMENTS_SIMPLE.include?(item.mods_path.path))
        path_array[0] = path_array[0].split(/(?<!^)(?=[A-Z])/)
        path_array[0] = path_array[0].join("_").downcase
      end
      path_array.each_with_index do |value, key|
        #The mods gem has special names for certain reserved words/paths
        if (RESERVED_WORDS.key?(value))
          path_array[key] = RESERVED_WORDS[value]
        end
      end
      
      subpaths = Array.new
      if (!item.mods_path.subpaths.blank?)
        if (!item.mods_path.delimiter.nil?)
          sub_delimiter = item.mods_path.delimiter
        end
        
        item.mods_path.subpaths.each do |subpath|
          subpath_array = subpath.split("/")
          subpath_array.each_with_index do |value, key|
            #The mods gem has special names for certain reserved words/paths
            if (RESERVED_WORDS.key?(value))
              subpath_array[key] = RESERVED_WORDS[value]
            end
          end

          subpaths << subpath_array
        end
      end

       values = Array.new
       
       node = parentnode

       #eg: subject
       path_array.each do |path|
         node = node.send(path) 
       end
       
       if (!subpaths.empty?)
          
          #subnodes when paths are stored in subpaths in the mapping file
          node.each do |subnode| 
            if (check_attributes(subnode, item))
              subpathvalues = Array.new
  
              value = find_node_value(subnode, subpaths,  [], 0) 
              if (!value.empty?)
                subpathvalues << value
                end
               if (!subpathvalues.empty? && check_conditional_subpath(subnode, item, parentnode))
                 values << subpathvalues.join(sub_delimiter)
               end
            end
         end
       else
   
         node.each do |subnode|
          if (!subnode.text.blank? && check_attributes(subnode, item) && check_conditional_path(subnode, item, parentnode))
            values << subnode.text
          end
         end
       end

      values
    end
    
    #Loops through the nodes to find the supplied subpaths.  It is done this way to preserve the mods order of the subpath values
    def find_node_value(nodeset, subpaths, parentpathname, popcount) 
      values = []
      pathname = parentpathname

      nodeset.children.each do |node|

        nodename = node.name
        
        if (RESERVED_WORDS.key?(nodename))
          nodename = RESERVED_WORDS[nodename]
        end
        if (!nodename.eql?('text'))
          pathname << nodename
          popcount = popcount + 1
          if (subpaths.include?(pathname))
            if (!node.text.blank?)
              values << node.text
            end
            #If the paths have multiple levels, then we have to back out to the original nodepath.
            until (popcount == 0) do
              pathname.pop
              popcount = popcount - 1;
            end
          elsif (node.children.count > 1 || (node.children.first == 1 && !node.children.first.name.eql?('text')))
            values += find_node_value(node, subpaths, pathname, popcount+1)
            until (popcount == 0) do
              pathname.pop
              popcount = popcount - 1;
            end
          end
        end
      end
      values
    end
    
    #Make sure that the attribute value matches (if supplied)
    def check_attributes(node, item)
     value_accepted = false
     if (!item.mods_attribute.blank?)
        if (item.mods_attribute[0].eql?("!") && node[item.mods_attribute.delete("!")].blank?)
          value_accepted = true
        elsif (!item.mods_attribute[0].eql?("!"))
          if (!item.mods_attribute_value.blank? && item.mods_attribute_value[0].eql?("!") && !node[item.mods_attribute].eql?(item.mods_attribute_value.delete("!")))
            value_accepted = true
          elsif (!node[item.mods_attribute].nil? && node[item.mods_attribute].eql?(item.mods_attribute_value))
            value_accepted = true
          end
        end
      else
        value_accepted = true
      end
      value_accepted
    end
    
    #Make sure the conditional path value matches (if supplied)
    def check_conditional_path(node, item, parentnode)
      value_accepted = false
      if (!item.conditional_mods_value.blank?)
          path_array = item.conditional_mods_path.split("/")
          path_array[0] = path_array[0].split(/(?<!^)(?=[A-Z])/)
          path_array[0] = path_array[0].join("_").downcase
          path_array.each_with_index do |value, key|
            #The mods gem has special names for certain reserved words/paths
            if (RESERVED_WORDS.key?(value))
              path_array[key] = RESERVED_WORDS[value]
            end
          end
          conditionalnode = parentnode
          path_array.each do |path|
            conditionalnode = conditionalnode.send(path)    
          end
          if (item.conditional_mods_value[0].eql?("!") && !conditionalnode.text.eql?(item.conditional_mods_value.delete("!")))
            value_accepted = true
          elsif (conditionalnode.text.eql?(item.conditional_mods_value))
            value_accepted = true
          end
      else
        value_accepted = true
      end
      value_accepted
    end
    
#Make sure the conditional path value matches (if supplied)
    def check_conditional_subpath(node, item, parentnode)
      value_accepted = false
      if (!item.conditional_mods_value.blank?)
          path_array = item.conditional_mods_path.split("/")
          path_array[0] = path_array[0].split(/(?<!^)(?=[A-Z])/)
          path_array[0] = path_array[0].join("_").downcase
          path_array.each_with_index do |value, key|
            #The mods gem has special names for certain reserved words/paths
            if (RESERVED_WORDS.key?(value))
              path_array[key] = RESERVED_WORDS[value]
            end
          end
          conditionalnode = node
          path_array.each do |path|
            conditionalnode = conditionalnode.send(path)     
          end
          
          if (item.conditional_mods_value[0].eql?("!") && !conditionalnode.text.eql?(item.conditional_mods_value.delete("!")))
            value_accepted = true
          elsif (conditionalnode.text.eql?(item.conditional_mods_value))
            value_accepted = true
          end
      else
        value_accepted = true
      end
      value_accepted
    end
end
  
  class OaipmhModsConverter
    RESERVED_PATHS = {'name/namePart'=> "plain_name/namePart", "name/role/roleTerm" => "plain_name/role/roleTerm"}
    STANDARD_SPOTLIGHT_FIELDS = ['unique-id_tesim', 'full_title_tesim', 'spotlight_upload_description_tesim', 'thumbnail_url_ssm', 'full_image_url_ssm', 'spotlight_upload_date_tesim"', 'spotlight_upload_attribution_tesim']
      
    attr_accessor :sidecar_hash
       
    #Initialize with the name of the set being converted
    def initialize(set, exhibitslug, mapping_file)
      @set = set
      @exhibitslug = exhibitslug
      @mapping_file = mapping_file   
      @converter_items = Array.new  
      @sidecar_hash = {}
    end
    
    #Expects a Mods::Record parameter value
    def convert(modsrecord)
      if (@converter_items.empty?)
        parse_mapping_file(mapping_file)
      end
      
      solr_hash = {}
        
      @converter_items.each do |item|
        node = modsrecord.mods_ng_xml
        value = nil
        if (!item.xpath_string.nil?)
          values = Array.new
          if (!item.xpath_namespace_def.nil?)
          retnodes = node.xpath(item.xpath_string, {item.xpath_namespace_prefix => item.xpath_namespace_def})
          else
            retnodes = node.xpath(item.xpath_string)
          end
          if (retnodes.empty? && !item.default_value.blank?)
            value = item.default_value
            values << value
          elsif (!retnodes.empty?)
            retnodes.each do |retnode|
              values << retnode.text
            end
          end
          if (!values.empty?)
            value = values.join(item.delimiter)
          end
        else
          value = item.extract_value(modsrecord)
        end
        if (!value.nil? && !value.empty?)
          solr_hash[get_spotlight_field_name(item.spotlight_field)] = value
          @sidecar_hash[item.spotlight_field] = value
        end
      end
      solr_hash
    end
    
    #Some spotlight fields use the exhibit slug, others do not
    def get_spotlight_field_name(spotlight_field)      
      if (!STANDARD_SPOTLIGHT_FIELDS.include?(spotlight_field))
        spotlight_field = 'exhibit_' + @exhibitslug + '_' + spotlight_field
      end
      spotlight_field
    end
    

    #Retrieves the mapping file for the set, if one exists, otherwise uses the generic mapping file
    def mapping_file
      if (@mapping_file == nil)
        engine_root = Spotlight::Oaipmh::Resources::Engine.root
        @mapping_file = File.join(engine_root, 'config', 'mapping.yml')
      else
        @mapping_file = Rails.root.join("public/uploads/modsmapping", @mapping_file)
      end
      @mapping_file        
    end

  
  #private
  
   #parses the mapping file into a model
  def parse_mapping_file(file)
    
    mapping_config = YAML.load_file(file)
    mapping_config.each do |field|
      
      item = ConverterItem.new
      #validate the spotlight-field is not null
      if (!field.key?("spotlight-field") || field['spotlight-field'].blank?)
        raise InvalidMappingFile, "spotlight-field is required for each entry"
      end
      item.spotlight_field = field['spotlight-field']
      
      if (field.key?("delimiter"))
        item.delimiter = field["delimiter"]
      end
      if (field.key?("default-value"))
        item.default_value = field["default-value"]
      end
      
      #must have a mods or xpath 
      if (!field.key?("mods") && (!field.key?('xpath') || field['xpath'].blank?))
        raise InvalidMappingFile, "mods or xpath is required for each entry"
      end
      
      #Can only have mods OR xpath
      if (field.key?('mods') && field.key('xpath'))
        raise InvalidMappingFile, "Use either mods OR xpath for each entry but not both"
      end
      
      #if using xpath, then add the values from xpath
      if (field.key?('xpath'))
        item.xpath_string = field['xpath']
        if (field.key?('xpath_namespace_prefix') && field.key?('xpath_namespace_def'))
          item.xpath_namespace_def = field['xpath_namespace_def']
          item.xpath_namespace_prefix = field['xpath_namespace_prefix']
        end
      #otherwise use mods
        else
        item.mods_items = Array.new
        field['mods'].each do |mods_field|
          modsitem = ModsItem.new
          #validate the path is not null
          if (!mods_field.key?("path") || mods_field['path'].blank?)
            raise InvalidMappingFile, "path is required for each mods entry"
          end
               
          modsitem.mods_path = ModsPath.new
          #The mods gem has special names for certain reserved words/paths
          if (RESERVED_PATHS.key?(mods_field['path']))
            modsitem.mods_path.path = RESERVED_PATHS[mods_field['path']]
          else
            modsitem.mods_path.path = mods_field['path']
          end
          
          
          if (mods_field.key?('subpaths'))
            subpaths = Array.new
            mods_field['subpaths'].each do |subpath|
              subpaths << subpath['subpath']
            end
            modsitem.mods_path.subpaths = subpaths
          end
          
          if (mods_field.key?('delimiter'))
            modsitem.mods_path.delimiter = mods_field['delimiter']
          end
          modsitem.conditional_mods_value = mods_field['mods-value']
                
          if (mods_field.key?('attribute'))
            if (!mods_field.key?('attribute-value'))
              raise InvalidMappingFile, field['spotlight-field'] + " - " + mods_field['path'] + ": attribute-value is required if attribute is present" 
            end
            modsitem.mods_attribute = mods_field['attribute']
            modsitem.mods_attribute_value = mods_field['attribute-value']
          end
          
          if (mods_field.key?('mods-path'))
            if (!mods_field.key?('mods-value'))
              raise InvalidMappingFile, field['spotlight-field'] + " - " + mods_field['path'] + ": mods-value is required if mods-path is present" 
            end
            if (RESERVED_PATHS.key?(mods_field['mods-path']))
              modsitem.conditional_mods_path = RESERVED_PATHS[mods_field['mods-path']]
            else
              modsitem.conditional_mods_path = mods_field['mods-path']
            end
            modsitem.conditional_mods_value = mods_field['mods-value']
          end
                  
          item.mods_items << modsitem
        end #mods
      end
      @converter_items << item
    end
    @converter_items
  end
  
  
  end
end