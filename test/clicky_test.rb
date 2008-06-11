require 'test/unit'

require 'rubygems'
require 'flexmock'
require 'flexmock/test_unit'

require File.join(File.dirname(__FILE__), '..', 'lib', 'clicky')

class ClickyTest < Test::Unit::TestCase
  
  def setup
    Clicky.configure!({})
    @clicky = Clicky.new
  end

  def test_configuration_methods_raise_when_not_passed_hashes
    assert_raises(ArgumentError) { Clicky.configure(1) }
    assert_raises(ArgumentError) { Clicky.configure!(1) }
  end
  
  def test_configure_bang_overwrites_configuration
    Clicky.configure!(:foo => 1, :bar => 2)
    Clicky.configure!(:baz => 3)
    assert_equal({:baz => 3}, Clicky.config)
  end
  
  def test_configure_merges_configuration
    Clicky.configure!(:foo => 1, :bar => 2)
    Clicky.configure(:foo => 2)
    assert_equal({:foo => 2, :bar => 2}, Clicky.config)
  end
  
  def test_instance_config_is_merged_correctly
    Clicky.configure!(:foo => 100, :bar => 200)
    config = Clicky.new(:foo => 200).instance_eval { @config } # dubious.
    assert_equal({:foo => 200, :bar => 200}, config)
  end
  
  def test_actions_result_is_parsed_correctly
    results = result_from_fixture('actions', Clicky::ActionResponse)
    first = results.first
    assert first.time.is_a?(Time)
    assert first.custom.is_a?(Hash)
  end
  
  def test_visitors_result_is_parsed_correctly
    results = result_from_fixture('visitors', Clicky::VisitorResponse)
    first = results.first
    assert first.time.is_a?(Time)
    assert first.latitude.is_a?(Float)
    assert first.longitude.is_a?(Float)
    assert first.actions.is_a?(Fixnum)
    assert [TrueClass, FalseClass].include?(first.javascript.class)
    assert first.custom.is_a?(Hash)
  end
  
  def test_tally_result_is_parsed_correctly
    results = result_from_fixture('tally', Clicky::TallyResponse)
    first = results.first
    assert first.value_percent.is_a?(Float)
    assert first.value.is_a?(Fixnum)
  end

  # This doesn't work and is slightly over the top anyway.
  # def test_requests_are_relayed_via_http
  #   begin
  #     Clicky.configure!(:site_id => 1, :sitekey => 'abcd')
  #     @clicky = Clicky.new
  #     url = @clicky.send(:request_path_for_action, @clicky.send(:option_set_for_action, 'test_action', {}))
  #     flexmock(Net::HTTP).new_instances.should_receive(:get).once.with(url).and_return(Net::HTTPNotFound.new)
  #     @clicky.test_action
  #   rescue
  #     # We've mocked Net::HTTP to return a not-found status
  #     # This doesn't matter because all we care about is that the correct parameters were passed
  #     # to the HTTP request object
  #   end
  # end
  
  def test_error_when_options_do_not_include_site_id
    assert_raises(ArgumentError) { @clicky.send(:parse_options, :sitekey => 'foo') }
  end
  
  def test_error_when_options_do_not_include_sitekey
    assert_raises(ArgumentError) { @clicky.send(:parse_options, :site_id => '123') }
  end
  
  def test_no_error_when_options_include_site_id_and_sitekey
    @clicky.send(:parse_options, :site_id => '123', :sitekey => 'foo')
  end
  
  def test_output_format_is_always_xml
    assert_url_contains_option(:output, 'xml')
    assert_url_contains_option(:output, 'xml', :output => 'csv')
  end
  
  def test_default_limit_is_10
    assert_url_contains_option(:limit, '10')
  end
  
  def test_false_limit_becomes_all
    assert_url_contains_option(:limit, 'all', :limit => false)
  end
  
  def test_explicity_limit_is_included
    assert_url_contains_option(:limit, '500', :limit => 500)
  end
  
  def test_date_defaults_to_today
    assert_url_contains_option(:date, 'today')
  end
  
  def test_date_specified_as_text_has_spaces_converted_to_dashes
    assert_url_contains_option(:date, 'last-week', :date => 'last week')
  end
  
  def test_date_specified_as_date_is_formatted_correctly
    assert_url_contains_option(:date, '2007-12-25', :date => Time.utc(2007, 12, 25))
  end
  
  def test_date_specifed_as_range_is_formatted_correctly
    assert_url_contains_option(:date, '2007-12-01,2007-12-31', :from => Time.utc(2007, 12, 1), :to => Time.utc(2007, 12, 31))
  end
  
  private
  
  def augment_options(options = {})
    options.update(:site_id => 123, :sitekey => 'foobar')
  end
  
  def assert_url_contains_option(key, value, options = {})
    parsed_options = @clicky.send(:parse_options, augment_options(options))
    url = @clicky.send(:request_path_for_action, parsed_options)
    assert url =~ /#{key}=#{value}/
  end
  
  def result_from_fixture(fixture, klass)
    results = @clicky.send(:result_array_from_xml_document,
                           REXML::Document.new(
                             File.new(
                               File.join(File.dirname(__FILE__), 'raw', fixture + '.xml'))),
                           klass)
    assert results.all? { |i| i.is_a?(klass) }
    results
  end

end