require "asari/version"

require "asari/collection"
require "asari/exceptions"

require "httparty"

require "ostruct"
require "json"
require "cgi"

class Asari
  def self.mode
    @@mode
  end

  def self.mode=(mode)
    @@mode = mode
  end

  attr_writer :api_version
  attr_writer :search_domain

  def initialize(search_domain=nil)
    @search_domain = search_domain 
  end

  # Public: returns the current search_domain, or raises a
  # MissingSearchDomainException.
  #
  def search_domain
    @search_domain || raise(MissingSearchDomainException.new)
  end

  # Public: returns the current api_version, or the sensible default of
  # "2011-02-01" (at the time of writing, the current version of the
  # CloudSearch API).
  #
  def api_version
    @api_version || "2011-02-01"
  end

  # Public: Search for the specified term.
  #
  # Examples:
  #
  #     @asari.search("fritters") #=> ["13","28"]
  #
  # Returns: An Asari::Collection containing all document IDs in the system that match the
  #   specified search term. If no results are found, an empty Asari::Collection is
  #   returned.
  #
  # Raises: SearchException if there's an issue communicating the request to
  #   the server.
  def search(term, options = {})
    return Asari::Collection.sandbox_fake if self.class.mode == :sandbox

    page_size = options[:page_size].nil? ? 10 : options[:page_size].to_i

    url = "http://search-#{search_domain}.us-east-1.cloudsearch.amazonaws.com/#{api_version}/search?q=#{CGI.escape(term)}&size=#{page_size}"

    if options[:page]
      start = (options[:page].to_i - 1) * page_size
      url << "&start=#{start}"
    end

    begin
      response = HTTParty.get(url)
    rescue Exception => e
      ae = Asari::SearchException.new("#{e.class}: #{e.message}")
      ae.set_backtrace e.backtrace
      raise ae
    end

    unless response.response.code == "200"
      raise Asari::SearchException.new("#{response.response.code}: #{response.response.msg}")
    end

    Asari::Collection.new(response, page_size)
  end

  # Public: Add an item to the index with the given ID.
  #   
  #     id - the ID to associate with this document
  #     fields - a hash of the data to associate with this document. This
  #       needs to match the search fields defined in your CloudSearch domain.
  #
  # Examples:
  #
  #     @asari.update_item("4", { :name => "Party Pooper", :email => ..., ... }) #=> nil
  #
  # Returns: nil if the request is successful.
  #
  # Raises: DocumentUpdateException if there's an issue communicating the
  #   request to the server.
  #
  def add_item(id, fields)
    return nil if self.class.mode == :sandbox
    query = { "type" => "add", "id" => id.to_s, "version" => 1, "lang" => "en" }
    fields.each do |k,v|
      fields[k] = "" if v.nil?
    end

    query["fields"] = fields
    doc_request(query)
  end

  # Public: Update an item in the index based on its document ID.
  #   Note: As of right now, this is the same method call in CloudSearch
  #   that's utilized for adding items. This method is here to provide a
  #   consistent interface in case that changes.
  # 
  # Examples:
  #     
  #     @asari.update_item("4", { :name => "Party Pooper", :email => ..., ... }) #=> nil
  #
  # Returns: nil if the request is successful.
  #
  # Raises: DocumentUpdateException if there's an issue communicating the
  #   request to the server.
  #
  def update_item(id, fields)
    add_item(id, fields)
  end

  # Public: Remove an item from the index based on its document ID.
  #
  # Examples:
  #   
  #     @asari.search("fritters") #=> ["13","28"]
  #     @asari.remove_item("13") #=> nil
  #     @asari.search("fritters") #=> ["28"]
  #     @asari.remove_item("13") #=> nil
  #
  # Returns: nil if the request is successful (note that asking the index to
  #   delete an item that's not present in the index is still a successful
  #   request).
  # Raises: DocumentUpdateException if there's an issue communicating the
  #   request to the server.
  def remove_item(id)
    return nil if self.class.mode == :sandbox

    query = { "type" => "delete", "id" => id.to_s, "version" => 2 }
    doc_request query
  end

  # Internal: helper method: common logic for queries against the doc endpoint.
  #
  def doc_request(query)
    endpoint = "http://doc-#{search_domain}.us-east-1.cloudsearch.amazonaws.com/#{api_version}/documents/batch"

    options = { :body => [query].to_json, :headers => { "Content-Type" => "application/json"} }

    begin
      response = HTTParty.post(endpoint, options)
    rescue Exception => e
      ae = Asari::DocumentUpdateException.new("#{e.class}: #{e.message}")
      ae.set_backtrace e.backtrace
      raise ae
    end

    unless response.response.code == "200"
      raise Asari::DocumentUpdateException.new("#{response.response.code}: #{response.response.msg}")
    end

    nil
  end
end

Asari.mode = :sandbox # default to sandbox
