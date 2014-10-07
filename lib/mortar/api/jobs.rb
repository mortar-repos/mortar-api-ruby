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

require 'set'

module Mortar
  class API
    module Jobs

      STATUS_STARTING          = "starting"
      STATUS_GATEWAY_STARTING  = "GATEWAY_STARTING" #Comes from task.
      STATUS_VALIDATING_SCRIPT = "validating_script"
      STATUS_SCRIPT_ERROR      = "script_error"
      STATUS_PLAN_ERROR        = "plan_error"
      STATUS_STARTING_CLUSTER  = "starting_cluster"
      STATUS_RUNNING           = "running"
      STATUS_SUCCESS           = "success"
      STATUS_EXECUTION_ERROR   = "execution_error"
      STATUS_SERVICE_ERROR     = "service_error"
      STATUS_STOPPING          = "stopping"
      STATUS_STOPPED           = "stopped"

      LUIGI_JOB_STATUS__PENDING           = 'pending'
      LUIGI_JOB_STATUS__STARTING          = 'starting'
      LUIGI_JOB_STATUS__RUNNING           = 'running'
      LUIGI_JOB_STATUS__FINISHED          = 'finished'
      LUIGI_JOB_STATUS__STOPPED           = 'stopped'
      LUIGI_JOB_STATUS__STOPPING          = 'stopping'


      STATUSES_IN_PROGRESS    = Set.new([STATUS_STARTING,
                                         STATUS_GATEWAY_STARTING,
                                         STATUS_VALIDATING_SCRIPT, 
                                         STATUS_STARTING_CLUSTER, 
                                         STATUS_RUNNING, 
                                         STATUS_STOPPING,
                                         LUIGI_JOB_STATUS__PENDING,
                                         LUIGI_JOB_STATUS__STARTING,
                                         LUIGI_JOB_STATUS__RUNNING,
                                         LUIGI_JOB_STATUS__STOPPING])

      STATUSES_COMPLETE       = Set.new([STATUS_SCRIPT_ERROR, 
                                        STATUS_PLAN_ERROR,
                                        STATUS_SUCCESS,
                                        STATUS_EXECUTION_ERROR,
                                        STATUS_SERVICE_ERROR,
                                        STATUS_STOPPED,
                                        LUIGI_JOB_STATUS__FINISHED,
                                        LUIGI_JOB_STATUS__STOPPED])

      CLUSTER_TYPE__SINGLE_JOB = 'single_job'
      CLUSTER_TYPE__PERSISTENT = 'persistent'
      CLUSTER_TYPE__PERMANENT = 'permanent'

      JOB_TYPE_ALL   = 'all'
      JOB_TYPE_PIG   = 'pig'
      JOB_TYPE_LUIGI = 'luigi'
    end
    
    
    # POST /vX/jobs
    def post_pig_job_existing_cluster(project_name, script_name, git_ref, cluster_id, options={})
      parameters = options[:parameters] || {}
      notify_on_job_finish = options[:notify_on_job_finish].nil? ? true : options[:notify_on_job_finish]
      is_control_script = options[:is_control_script] || false
      
      body = {"project_name" => project_name,
        "git_ref" => git_ref,
        "cluster_id" => cluster_id,
        "parameters" => parameters,
        "notify_on_job_finish" => notify_on_job_finish,
        "job_type" => Jobs::JOB_TYPE_PIG
      }
      
      if is_control_script
        body["controlscript_name"] = script_name
      else
        body["pigscript_name"] = script_name
      end

      #If no pig_version is set, leave it to server to figure out version.
      unless options[:pig_version].nil?
        body["pig_version"] = options[:pig_version]
      end

      unless options[:project_script_path].nil?
        body["project_script_path"] = options[:project_script_path]
      end

      request(
        :expects  => 200,
        :method   => :post,
        :path     => versioned_path("/jobs"),
        :body     => json_encode(body))
    end

    # POST /vX/jobs
    def post_pig_job_new_cluster(project_name, script_name, git_ref, cluster_size, options={})
      cluster_type = options[:cluster_type].nil? ? Jobs::CLUSTER_TYPE__PERSISTENT : options[:cluster_type]
      notify_on_job_finish = options[:notify_on_job_finish].nil? ? true : options[:notify_on_job_finish]
      use_spot_instances = options[:use_spot_instances].nil? ? false : options[:use_spot_instances]
      parameters = options[:parameters] || {}
      is_control_script = options[:is_control_script] || false

      body = { "project_name" => project_name,
        "git_ref" => git_ref,
        "cluster_size" => cluster_size,
        "cluster_type" => cluster_type,
        "parameters" => parameters,
        "notify_on_job_finish" => notify_on_job_finish,
        "job_type" => Jobs::JOB_TYPE_PIG,
        "use_spot_instances" => use_spot_instances
      }
      if is_control_script
        body["controlscript_name"] = script_name
      else
        body["pigscript_name"] = script_name
      end

      #If no pig_version is set, leave it to server to figure out version.
      unless options[:pig_version].nil?
        body["pig_version"] = options[:pig_version]
      end

      unless options[:project_script_path].nil?
        body["project_script_path"] = options[:project_script_path]
      end

      request(
        :expects  => 200,
        :method   => :post,
        :path     => versioned_path("/jobs"),
        :body     => json_encode(body))
    end

    def post_luigi_job(project_name, luigiscript_name, git_ref, options={})
      parameters = options[:parameters] || {}
      body = { "project_name" => project_name,
        "git_ref" => git_ref,
        "luigiscript_name" => luigiscript_name,
        "parameters" => parameters,
        "job_type" => Jobs::JOB_TYPE_LUIGI
      }
      unless options[:project_script_path].nil?
        body["project_script_path"] = options[:project_script_path]
      end

      request(
        :expects  => 200,
        :method   => :post,
        :path     => versioned_path("/jobs"),
        :body     => json_encode(body))
    end

    # GET /vX/jobs
    def get_jobs(skip, limit, job_type=Jobs::JOB_TYPE_PIG)
      request(
        :expects  => 200,
        :idempotent => true,
        :method   => :get,
        :path     => versioned_path("/jobs"),
        :query    => { job_type => job_type, :skip => skip, :limit => limit }
      )
    end
    
    # GET /vX/jobs/:job_id
    def get_job(job_id)
      request(
        :expects  => 200,
        :idempotent => true,
        :method   => :get,
        :path     => versioned_path("/jobs/#{job_id}")
      )
    end

    # DELETE /v2/jobs/:job_id
    def stop_job(job_id)
      request(
        :expects => 200,
        :idempotent => true,
        :method  => :delete,
        :path    => versioned_path("/jobs/#{job_id}")
      )
    end

    # <b>DEPRECATED:</b> Please use <tt>post_pig_job_existing_cluster</tt> instead.
    def post_job_existing_cluster(project_name, script_name, git_ref, cluster_id, options={})
      warn "[DEPRECATION] 'post_job_existing_cluster' is deprecated.  Please use 'post_pig_job_existing_cluster' instead."
      post_pig_job_existing_cluster(project_name, script_name, git_ref, cluster_id, options=options)
    end

    # <b>DEPRECATED:</b> Please use <tt>post_pig_job_new_cluster</tt> instead.
    def post_job_new_cluster(project_name, script_name, git_ref, cluster_size, options={})
      warn "[DEPRECATION] 'post_job_new_cluster' is deprecated.  Please use 'post_pig_job_new_cluster' instead."
      post_pig_job_new_cluster(project_name, script_name, git_ref, cluster_size, options=options)
    end

  end
end
