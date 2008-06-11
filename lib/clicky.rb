require 'net/http'
require 'rexml/document'
require 'date'

# First, configure the Clicky gem with your site ID/key, as provided by Clicky.
#
# <tt>Clicky.configure!(:site_id => 1234, :sitekey => '12345678abcd')</tt>
#
# Then instantiate a Clicky instance and request the required report
# (which is just an array of result objects):
#
# <tt>
# clicky = Clicky.new
# report = clicky.actions_list
# </tt>
#
# Result objects will be instances of subclasses of Clicky::Response; see the
# class documentation pages for more info.
#
# A complete list of available reports is available at http://getclicky.com/help/api -
# replace the dashes in report names with underscores to get the corresponding method.
# There's also Clicky::Actions - this module defines a grouped data structure of
# report names and descriptions. You could use this to create a report list in your
# CMS if that takes your fancy.
#
# Query parameters are supported by passing an additional options hash, e.g.:
#
# <tt>report = clicky.pages(:limit => false, :date => Date.today)</tt>
# 
# Valid keys are:
#
# - <tt>:limit</tt> - maximum number of results to return. Defaults to 10, set to <tt>false</tt> for no limit.
# - <tt>:date</tt> - date for which to return data.
# - <tt>:from</tt> - start date if searching by date range.
# - <tt>:to</tt> - end date if searching by date range.
# - <tt>:site_id</tt> - your site ID, as assigned by Clicky
# - <tt>:site_key</tt> - your site key, as assigned by Clicky
#
# Valid dates for :date, :from and :to are instances of <tt>Date</tt>/<tt>Time</tt>,
# or date string formatted as YYYY-mm-dd. :date also supports relative dates in English,
# like "today", "3-days-ago" and "last-month". Again, see the Clicky API docs for a
# comprehensive list of what's supported.
#
# A bunch of keys are currently unsupported:
# ip_address, search, domain, link, browser, os, resolution, country, city, language,
# hostname, organization, custom, session_id, title, href, action_type
# 
class Clicky
  
  class ResponseError < RuntimeError; end
  
  # Base URL for the Clicky API service
  BASE_URL = URI.parse("http://api.getclicky.com/stats/api2")
  
  @@config = { :app => 'clicky-ruby' }
  
  # Update the default Clicky configuration by merging <tt>options</tt> with
  # the current default options.
  def self.configure(options)
    raise ArgumentError unless options.is_a?(Hash)
    @@config.update(options)
  end
  
  # Update the default Clicky configuration by replacing the current default
  # options with <tt>options</tt>.
  def self.configure!(options)
    raise ArgumentError unless options.is_a?(Hash)
    @@config = options.dup
  end
  
  # Returns the current default Clicky configuration, as used by new instances.
  def self.config
    @@config.dup
  end
  
  # Create a new instance. 
  # <tt>config</tt> - hash of options to be merged with the current default
  # configuration. Valid option keys are identical to those supported by
  # the action methods, as documented above.
  def initialize(config = {})
    @config = @@config.merge(config)
  end
  
  def method_missing(method, options = {}, &block) # :nodoc:
    action = method.to_s.gsub('_', '-')
    options = option_set_for_action(action, options)
    result_array_from_xml_document(get(options), response_class_for_action(action))
  end
  
  private
  
  def response_class_for_action(action)
    case action
      when 'visitors-list':                       VisitorResponse
      when 'actions-list':                        ActionResponse
      when /^(searches|links)-(recent|unique)$/:  ChronoResponse
      else                                        TallyResponse
    end
  end
  
  def get(options)
    res = Net::HTTP.start(BASE_URL.host, BASE_URL.port) do |http|
      http.get(request_path_for_action(options))
    end
    
    if !res.is_a?(Net::HTTPSuccess)
      raise ResponseError.new('Non-success HTTP response')
    elsif res.body.length == 0
      raise ResponseError.new('Zero-length response')
    end
    
    REXML::Document.new(res.body)
  end
  
  def request_path_for_action(options)
    BASE_URL.path + "?#{options.map { |k,v| "#{k}=#{v}" }.join('&')}"
  end
  
  def format_date(date)
    date.strftime("%Y-%m-%d")
  end
  
  def option_set_for_action(action, options)
    parse_options(@config.merge(options).update(:type => action))
  end

  def parse_options(options)
    
    options[:output] = 'xml'
    
    if options.key?(:limit)
      options[:limit] = 'all' unless options[:limit]
    else
      options[:limit] = 10
    end
    
    if options[:date] && (options[:date].is_a?(Date) || options[:date].is_a?(Time))
      options[:date] = format_date(options[:date])
    elsif options[:from] && options[:to]
      options[:date] = "#{format_date(options.delete(:from))},#{format_date(options.delete(:to))}"
    else
      options[:date] = (options[:date] || 'today').gsub(' ', '-')
    end
    
    unless [:site_id, :sitekey].all? { |k| options.key?(k) }
      raise ArgumentError.new('Config keys :site_id and :sitekey are required')
    end
    
    options
    
  end
  
  def result_array_from_xml_document(document, klass)
    results = []
    document.elements.each('items/item') { |ele| results << klass.new(ele) }
    results
  end

  # Abstract superclass for all other response types
  class Response
    def initialize(node) # :nodoc:
      node.each_element do |child|
        instance_variable_set("@#{child.name}", parse_attribute(child.name, child))
      end
    end
    
    # if any custom data has been logged for this visitor (username, etc), this object
    # will contain a group of sub-objects for each key/value pair.
    def custom
      @custom || {}
    end
    
    # Hash-style accessor for response attributes. Accepts strings or symbols.
    def [](key)
      instance_variable_get("@#{key}")
    end
    
    private
    
    def parse_attribute(name, node)
      case name
        when 'time': Time.at(node.text.to_i)
        when 'javascript': node.text == '1'
        when 'value', 'actions', 'time_total': node.text.to_i
        when 'latitude', 'longitude', 'value_percent': node.text.to_f
        when 'custom': node.inject({}) { |m,n| m[n.name] = n.text; m }
        else node.text
      end
    end
  end
  
  # Response type returned for the +visitors_list+ action.
  class VisitorResponse < Response
    
    # the time of the visit
    attr_reader :time

    # the amount of time in seconds that this visitor was / has been on you site
    attr_reader :time_total

    # the visitor's IP address
    attr_reader :ip_address

    # the session_id for this visit
    attr_reader :session_id

    # the number of actions performed (page views, downloads, outbound links clicked)
    attr_reader :actions

    # the visitor's web browser, e.g. "Firefox"
    attr_reader :web_browser

    # the visitor's operating system, e.g. "Windows"
    attr_reader :operating_system

    # the visitor's screen resolution, e.g. "1024x768"
    attr_reader :screen_resolution

    # does this user have javascript enabled?
    attr_reader :javascript

    # the spoken language of the visitor
    attr_reader :language

    # if the visitor followed a link to your site, this is where they came from
    attr_reader :referer_url

    # the domain of the referer, if applicable
    attr_reader :referer_domain

    # the search term used to get to your site, if applicable
    attr_reader :referer_search

    # the visitor's location in City, Country format (City, State, Country for US locations)
    attr_reader :geolocation

    # the visitor's latitude
    attr_reader :latitude

    # the visitor's longitude
    attr_reader :longitude

    # a link to view the details of the visitor session on Clicky
    attr_reader :clicky_url

  end
  
  # Response type returned for the +actions_list+ action.
  class ActionResponse < Response
    
    # Time of the visit
    attr_reader :time

    # Visitor's IP address, as a string
    attr_reader :ip_address

    # Session ID that this action belongs to
    attr_reader :session_id

    # Type of action performed.
    # Possible values are "pageview", "download", or "outbound".
    attr_reader :action_type

    # For page views, this is the HTML title of the page.
    # For downloads and outbound links, this is the anchor text used to
    # initiate the action. If it's a graphical link, we grab
    # the "alt" or "title" attribute if available. Otherwise we fall back on
    # the URL of the image itself.
    attr_reader :action_title

    # The URL of the page view, download, or outbound link
    attr_reader :action_url

    # If this action was the result of an external link or search, this is
    # where the action came from (only applicable to "pageview" action types).
    attr_reader :referer_url

    # The refering domain, if applicable
    attr_reader :referer_domain

    # The search term used to get to your site, if applicable
    attr_reader :referer_search

    # A link to Clicky that shows further details on about the visitor's session
    attr_reader :clicky_url

  end
  
  class ChronoResponse < Response
    
    # the time of the visit
    attr_reader :time
    
    # the search query or link 
    attr_reader :item
    
    # A link to Clicky that shows further details on about the visitor's session
    attr_reader :clicky_url
    
  end
  
  # Response type returned for all actions other than +visitors_list+ and
  # +actions_list+.
  class TallyResponse < Response
    
    # The name, title or description of the item
    attr_reader :title

    # The item's value (typically, the number of occurences)
    attr_reader :value

    # The item's value as a percent of the total values of all other items in the same category
    attr_reader :value_percent

    # A URL of the item itself, if applicable (pages, incoming links, outbound links, etc)
    attr_reader :url

    # A link to view more details for this item on Clicky
    attr_reader :clicky_url

  end
end