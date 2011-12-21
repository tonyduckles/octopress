module Jekyll

  # The purpose of this plugin is to allow non-post pages show up the category
  # index pages.  Creates a new site attribute, "pages_guitartabs".  It's a hash of all
  # of the pages (not posts) that contain the category 'Guitar Tabs'.  This hash
  # uses the pages categories as the keys, and all of the pages with that
  # category are the values.
  #
  # Extensions to the Jekyll Site class. For use with Octopress.
  #
  # (Based on https://gist.github.com/1477711 by Tim Gray)

  class Site

    # add pages_guitartabs getter/setters
    def pages_guitartabs=(value)
      @pages_guitartabs = value
    end

    def pages_guitartabs
      @pages_guitartabs
    end

    # extend the site.reset method to initialize our pages_guitartabs variable
    alias orig_reset reset
    def reset
      orig_reset
      self.pages_guitartabs = []
    end

    # extend site.read to find our pages_guitartabs (pages with the tag 'Guitar Tabs')
    alias orig_read read
    def read
      orig_read
      self.pages.each do |page|
        if page.categories != nil
          if page.categories.include?('Guitar Tabs')
            pages_guitartabs << page
            page.categories.each { |c| self.categories[c] << page }
          end
        end
      end
    end

    def guitartabs_attr_hash(post_attr)
      # Build a hash map based on the specified post attribute ( post attr =>
      # array of posts ) then sort each array in reverse order.
      # Basically walk through self.pages_guitartabs, and then store guitartabs.category
      # to the hash.  This is what is going to get sent to site.pages_guitartabs, the
      # liquid template variable.
      hash = Hash.new { |hsh, key| hsh[key] = Array.new }
      self.pages_guitartabs.each do |p| 
        p.send(post_attr.to_sym).each { |t| hash[t] << p }
      end
      hash.values.map { |sortme| sortme.sort! { |a, b| b <=> a } }
      hash
    end

    # extend site_payload and stick our pages_guitartabs hash into it
    alias orig_site_payload site_payload
    def site_payload
      h = orig_site_payload
      payload = h["site"]
      payload["pages_guitartabs"] =  guitartabs_attr_hash('categories')
      h["site"] = payload
      h
    end
  end

  # Extensions to the Jekyll Page class.
  class Page

    # make pages have pretty permalinks
    def template
      if !index? && html?
        "/:basename/"
      else
        "/:basename:output_ext"
      end
    end

    # define some utility methods to make pages behave like posts a little bit more
    def date=(value)
      @date = value
    end
    def date
      @date
    end

    def categories=(value)
      @categories = value
    end
    def categories
      @categories
    end

    def <=>(other)
      cmp = self.date <=> other.date
      if 0 == cmp
        cmp = self.slug <=> other.slug
      end
      return cmp
    end

    def title
      if self.data.has_key?('title')
        self.data['title']
      end
    end

    def slug
      if self.data.has_key?('slug')
        self.data['slug']
      end
    end

    # extend initialize to give pages a date and categories
    alias orig_initialize initialize
    def initialize(site, base, dir, name)
      orig_initialize(site, base, dir, name)
      if self.data.has_key?('date')
        self.date = Time.parse(self.data["date"].to_s)
      end
      self.categories = []
      if self.categories.empty?
        self.categories = self.data.pluralized_array('category', 'categories')
      end
    end

    # extend to_liquid to store our new data
    alias orig_to_liquid to_liquid
    def to_liquid
      h = orig_to_liquid
      h['date'] = self.date
      h['categories'] = self.categories
      h
    end
  end

end
