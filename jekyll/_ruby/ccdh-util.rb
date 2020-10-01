require_relative 'ccdh-constants'

module CCDH


  # this is meant to check all syntax issues with a name/ID
  #
  # returns nil if it fails for any reason
  #
  # Some capitalization issues are handled without considering them an error
  #
  def self.ss_normalized_name_parts(ref)
    ref.gsub!(/[^a-zA-Z0-9#.\/]/, "") # remove any illegal
    ref.gsub(/\/+/, "/") # collapse accidental duplicate /
    ref.gsub(/#+/, "#") # collapse accidental duplicate #
    ref.gsub(/\.+/, ".") # collapse accidental duplicate .

    # max one . or #
    if ref.count(SEP_DOT) > 1 || ref.count(SEP_HASH) > 1
      return nil
    end

    np = ref.strip.split(SEP_NAME_PARTS)

    if np[0].nil? || np[0].empty?
      return nil
    end

    # this also forces at least 2 non empty parts
    case np[1]
    when V_TYPE_CONCEPT.upcase, V_TYPE_CONCEPT.downcase
      np[1] = V_TYPE_CONCEPT # normalize

    when V_TYPE_ELEMENT.upcase, V_TYPE_ELEMENT.downcase
      np[1] = V_TYPE_ELEMENT

    when V_TYPE_STRUCTURE.upcase, V_TYPE_STRUCTURE.downcase
      np[1] = V_TYPE_STRUCTURE

    when V_TYPE_PACKAGE.upcase, V_TYPE_PACKAGE.downcase
      np[1] = V_TYPE_PACKAGE

    when V_TYPE_MODEL.upcase, V_TYPE_MODEL.downcase
      np[1] = V_TYPE_MODEL

    when V_TYPE_MODEL_SET.upcase, V_TYPE_MODEL_SET.downcase
      np[1] = V_TYPE_MODEL_SET
    else
      # error
      return nil
    end

    if np[1] == V_TYPE_STRUCTURE
      np[0] = _normalize_structure_name(np[0])
    else
      # we need to further clean up names
      np[0].gsub!(/[^a-zA-Z0-9]/, "")
    end

    if np[0].nil? || np[0].empty?
      return nil
    end

    # all should be capitalized
    # except for attribute names which are handled in the structure name normalization
    np[1] != V_TYPE_STRUCTURE && np[0].capitalize!

    # if it's only two parts we're done
    if np.length == 2
      return np
    end

    # now we have 3 or more parts
    # part 1 and 2 is normalized at this point

    # first normalize parts 3 and 4
    #
    # it has be one of the following, or it's an error
    # Entity/Type/Package
    # Entity/Type/Package/P
    # Package/P/Model
    # Package/P/Model/M
    # Model/M/ModelSet
    # Model/M/ModelSet/MS

    # we need a Package, Model, or ModelSet name
    np[2].gsub!(/[^a-zA-Z0-9]/, "")

    if np[2].empty?
      return nil
    end
    # it should be capitalized
    np[2].capitalize!

    # for entities
    if np[1] == V_TYPE_CONCEPT || np[1] == V_TYPE_ELEMENT || np[1] == V_TYPE_STRUCTURE
      # has to have P after it or we can add it. otherwise it's an error, nil
      if np[3].nil? || np[3].upcase == V_TYPE_PACKAGE.upcase
        np[3] = V_TYPE_PACKAGE
      else
        return nil
      end
    end

    # for package
    if np[1] == V_TYPE_PACKAGE
      # it has to have a M after it, or we can add it. or it's an error
      if np[3].nil? || np[3].upcase == V_TYPE_MODEL.upcase
        np[3] = V_TYPE_MODEL
      else
        return nil
      end
    end

    # for model
    if np[1] == V_TYPE_MODEL
      # it has to have a MS or add it. or it's an error
      if np[3].nil? || np[3].upcase == V_TYPE_MODEL_SET.upcase
        np[3] = V_TYPE_MODEL_SET
      else
        return nil
      end
    end


    # now we have the first 4 parts normalized. if length is 4 return
    if np.length == 4
      return np
    end

    # now we have 5 or more parts

    # first normalize parts 5 and 6
    #
    # it has be one of the following, or nil
    # Entity/Type/Package/P/Model
    # Entity/Type/Package/P/Model/M
    # Package/P/Model/M/ModelSet
    # Package/P/Model/M/ModelSet/MS

    # we need a Model or ModelSet name
    np[4].gsub!(/[^a-zA-Z0-9]/, "")
    if np[4].empty?
      return nil
    end
    # it should be capitalized
    np[4].capitalize!

    # for entities
    if np[1] == V_TYPE_CONCEPT || np[1] == V_TYPE_ELEMENT || np[1] == V_TYPE_STRUCTURE
      # has to have P after it or we can add it. otherwise it's an error, nil
      if np[5].nil? || np[5].upcase == V_TYPE_MODEL.upcase
        np[5] = V_TYPE_MODEL
      else
        return nil
      end
    end

    # for package
    if np[1] == V_TYPE_PACKAGE
      # it has to have a M after it, or we can add it. or it's an error
      if np[5].nil? || np[3].upcase == V_TYPE_MODEL_SET.upcase
        np[5] = V_TYPE_MODEL_SET
      else
        return nil
      end
    end

    if np.length == 6
      return np
    end

    # now we have 7 or more parts

    # first normalize parts 7 and 8
    #
    # it has be one of the following, or nil
    # Entity/Type/Package/P/Model/M/ModelSet
    # Entity/Type/Package/P/Model/M/ModelSet/MS

    # we need a ModelSet name
    np[6].gsub!(/[^a-zA-Z0-9]/, "")
    if np[6].empty?
      return nil
    end
    # it should be capitalized
    np[6].capitalize!

    # for entities
    if np[1] == V_TYPE_CONCEPT || np[1] == V_TYPE_ELEMENT || np[1] == V_TYPE_STRUCTURE
      # has to have P after it or we can add it. otherwise it's an error, nil
      if np[7].nil? || np[7].upcase == V_TYPE_MODEL_SET.upcase
        np[7] = V_TYPE_MODEL_SET
      else
        return nil
      end
    end

    if np.length == 8
      return np
    end

    return nil
  end

  def self.ss_assemble_name_parts(parts)
    parts[1] == V_TYPE_STRUCTURE && parts[0] = ss_assemble_structure_parts(parts[0])
    parts.join(SEP_NAME_PARTS)
  end

  def self.ss_assemble_structure_parts(parts)
    structure_ref = parts[0]
    parts[1].nil? || structure_ref += SEP_HASH + parts[1]
    parts[2].nil? || structure_ref += SEP_DOT + parts[2]
    structure_ref
  end

  def self._normalize_structure_name(name)
    structure_name = nil
    id_name = nil
    attribute_name = nil

    # if it has an instance id
    if name.match?(SEP_HASH)
      # it has an id
      parts = name.split(SEP_HASH)
      if parts.length != 2 || parts[0].empty? || parts[1].empty?
        return nil
      end
      structure_name = parts[0]

      # see if we also have an attribute
      if parts[1].match?(SEP_DOT)
        # we should have two parts
        parts = parts[1].split(SEP_DOT)

        if parts.length != 2 || parts[0].empty? || parts[1].empty?
          return nil
        end
        id_name = parts[0]
        attribute_name = parts[1]

      else
        # no attribute
        id_name = parts[1]
      end

    elsif name.match?(SEP_DOT)
      # it has an attribute and no id
      parts = name.split(SEP_DOT)
      if parts.length != 2 || parts[0].empty?
        return nil
      end
      structure_name = parts[0]
      attribute_name = parts[1]

    else
      structure_name = name
    end
    name


    [structure_name.capitalize, id_name, attribute_name&.downcase]
  end

  def self.rr_is_entity_name(name)
    name.split(SEP_COLON).size == 3
  end

  def self.rr_is_fqn_name(name)
    name.split(SEP_COLON).size == 5
  end

  # Allows a-z, A-Z, 0-9, and _
  # If empty, generate with defaultName_randomNumber
  def self.r_check_simple_name(name, entity_type)
    name.nil? && name = ""
    name = name.gsub(/[^a-zA-Z0-9_]/, "")
    if name.empty?
      name = "#{entity_type}_#{rand(1000000..9999999)}"
    end

    # starts with alphabet except for V_SELF
    if name != V_SELF
      name =~ /^[a-zA-Z]/ || (name = entity_type + name)
    end
    name
  end

  def self.r_check_entity_name_bar_list(list, entity_type)
    newList = ""
    list.nil? && (return newList)
    list.split(SEP_BAR).collect(&:strip).reject(&:empty?).each do |sublist|
      newSublist = ""
      sublist.split(SEP_COMMA).collect(&:strip).reject(&:empty?).each do |entity_name|
        new_entity_name = r_check_entity_name(entity_name, entity_type)
        new_entity_name.empty? && next
        newSublist.empty? || newSublist += "#{SEP_COMMA} "
        newSublist += new_entity_name
      end
      newList.empty? || newSublist.empty? || newList += " #{SEP_BAR} "
      newList += newSublist
    end
    newList
  end

  def self.r_check_entity_name(entity_name, entity_type)
    parts = entity_name.split(SEP_COLON).collect(&:strip).reject(&:empty?)
    parts.size == 3 || (return "")
    p_name = r_check_simple_name(parts[2], V_TYPE_PACKAGE)
    t_name = entity_type
    e_name = r_check_simple_name(parts[0], entity_type)
    (p_name.empty? || t_name.empty? || e_name.empty?) && (return "")
    "#{e_name}#{SEP_COLON}#{t_name}#{SEP_COLON}#{p_name}"
  end

  def self.r_build_entry(entry, hash)
    (entry.nil? || entry.empty? || hash.nil?) && raise("build_entry had entry: #{entry} and hash.nil? #{hash.nil?}")
    hash[H_BUILD].nil? && hash[H_BUILD] = ""

    # some cleanups
    hash[H_BUILD] = hash[H_BUILD].gsub(/[\n\n]+/, "\n")
    hash[H_BUILD] = hash[H_BUILD].gsub(/[ ]+/, " ")
    hash[H_BUILD] = hash[H_BUILD].strip

    entry = entry.gsub(/[\n\n]+/, "\n")
    entry = entry.gsub(/[ ]+/, " ")

    unless hash[H_BUILD].empty?
      hash[H_BUILD].include?(entry) && return
      (hash[H_BUILD] += "\n")
    end

    hash[H_BUILD] += entry
  end

  # this does the AND query over the concept hierarchy
  def self.rr_concept_array_descendants(array)
    descendants = nil
    array.each do |c|
      if descendants.nil?
        descendants = c[K_DESCENDANTS].clone
        next
      end
      descendants.keep_if do |key, value|
        c[K_DESCENDANTS].has_key?(key)
      end
    end
    descendants
  end

  def self.rr_concepts_dag_roots(concepts)
    concepts_roots = concepts.clone
    concepts.each do |key, concept|
      concept[K_PARENTS].each do |parent|
        parent_key = parent[K_FQN]
        if concepts_roots.key?(parent_key)
          # if the parent is in the DAG, remove the child
          concepts_roots.delete(key)
        end
      end
    end
    concepts_roots
  end


end


puts CCDH::ss_assemble_name_parts CCDH::ss_normalized_name_parts("someStruct#123.Attrib/s/1ffa  ldf")
