#
# Copyright 2012 Mortar Data Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Portions of this code from heroku.rb (https://github.com/heroku/heroku.rb/),
# used under an MIT license 
# (https://github.com/heroku/heroku.rb/blob/56fa8ed4cba0ab7e5785d6df75a9de687237124f/README.md#meta).
#

require "excon"
require "securerandom"
require "uri"
require "zlib"

__LIB_DIR__ = File.expand_path(File.join(File.dirname(__FILE__), ".."))
unless $LOAD_PATH.include?(__LIB_DIR__)
  $LOAD_PATH.unshift(__LIB_DIR__)
end

require "mortar/api/vendor/okjson"


require "mortar/api/basicauth"
require "mortar/api/errors"
require "mortar/api/version"
require "mortar/api/clusters"
require "mortar/api/illustrate"
require "mortar/api/describe"
require "mortar/api/validate"
require "mortar/api/jobs"
require "mortar/api/login"
require "mortar/api/projects"
require "mortar/api/user"
require "mortar/api/tasks"
require "mortar/api/config"

srand

module Mortar
  class API
    
    include Mortar::API::BasicAuth
    
    attr_reader :connection
    
    def initialize(options={})
      user = options.delete(:user)
      api_key = options.delete(:api_key) || ENV['MORTAR_API_KEY']
      options = {
        :headers  => {},
        :host     => 'api.mortardata.com',
        :retry_limit => 5,
        :scheme   => 'https',
        :ssl_version => 'SSLv3'
      }.merge(options)
      options[:headers] = {
        'Accept'                => 'application/json',
        'Accept-Encoding'       => 'gzip',
        'Content-Type'          => 'application/json',
        #'Accept-Language'       => 'en-US, en;q=0.8',
        'Authorization'         => basic_auth_authorization_header(user, api_key),
        'User-Agent'            => "mortar-api-ruby/#{Mortar::API::VERSION}",
        'X-Ruby-Version'        => RUBY_VERSION,
        'X-Ruby-Platform'       => RUBY_PLATFORM
      }.merge(options[:headers])
      @connection = Excon.new("#{options[:scheme]}://#{options[:host]}", options)
    end

    def request(params, &block)
      begin
        response = @connection.request(params, &block)
      rescue Excon::Errors::HTTPStatusError => error
        klass = case error.response.status
          when 400 then Mortar::API::Errors::BadRequest
          when 401 then Mortar::API::Errors::Unauthorized
          when 402 then Mortar::API::Errors::VerificationRequired
          when 403 then Mortar::API::Errors::Forbidden
          when 404 then Mortar::API::Errors::NotFound
          when 408 then Mortar::API::Errors::Timeout
          when 409 then Mortar::API::Errors::Conflict
          when 422 then Mortar::API::Errors::RequestFailed
          when 423 then Mortar::API::Errors::Locked
          when /50./ then Mortar::API::Errors::RequestFailed
          else Mortar::API::Errors::ErrorWithResponse
        end

        reerror = klass.new(error.message, error.response)
        reerror.set_backtrace(error.backtrace)
        raise(reerror)
      end

      if response.body && !response.body.empty?
        if response.headers['Content-Encoding'] == 'gzip'
          response.body = Zlib::GzipReader.new(StringIO.new(response.body)).read
        end
        begin
          response.body = Mortar::API::OkJson.decode(response.body)
        rescue
          # leave non-JSON body as is
        end
      end

      #Check if we got a redirect and treat it as an error.
      if response.body.include? "redirect"
        redirect_error = Mortar::API::Errors::Redirect.new(response.body["error"], response.body)
        raise(redirect_error)
      end

      # reset (non-persistent) connection
      @connection.reset

      response
    end

    def versioned_path(resource)
      no_slash_resource = resource.start_with?("/") ? resource[1,resource.size] : resource
      "/v#{SERVER_API_VERSION}/#{no_slash_resource}"
    end
    
    protected

    def json_encode(object)
      Mortar::API::OkJson.encode(object)
    end

    def escape(string)
      CGI.escape(string).gsub('.', '%2E')
    end

  end
end
