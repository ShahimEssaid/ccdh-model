module Jekyll
  class Site

    def reset_and_prepend_includes(prepend_array, append_array)
      configure_include_paths # this sets it back to default
      unless prepend_array.nil? || prepend_array.empty?
        includes_load_paths.unshift(*prepend_array)
      end

      unless append_array.nil? || append_array.empty?
        includes_load_paths.append(*append_array)
      end

    end
  end

  class Page

    def get_relative_path
      @relative_path
    end
  end
end
