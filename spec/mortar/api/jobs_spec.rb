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

require "base64"
require "spec_helper"
require "mortar/api"


describe Mortar::API do
  
  before(:each) do
    @api = Mortar::API.new
  end
  
  after(:each) do
    Excon.stubs.clear
  end

  context "jobs" do
    it "posts a pig job for an existing cluster" do
      job_id = "7b93e4d3ab034188a0c2be418d3d24ed"
      project_name = "my_project"
      pigscript_name = "my_pigscript"
      project_script_path = "pigscripts/"
      git_ref = "e20395b8b06fbf52e86665b0660209673f311d1a"
      cluster_id = "f82c774f7ccd429e91db996838cb6c4a"
      parameters = {"my_first_param" => 1, "MY_SECOND_PARAM" => "TWO"}
      body = Mortar::API::OkJson.encode({"project_name" => project_name,
                                         "git_ref" => git_ref,
                                         "cluster_id" => cluster_id,
                                         "parameters" => parameters,
                                         "notify_on_job_finish" => true,
                                         "job_type" => "pig",
                                         "pigscript_name" => pigscript_name,
                                         "project_script_path" => project_script_path})
      Excon.stub({:method => :post, :path => "/v2/jobs", :body => body}) do |params|
        {:body => Mortar::API::OkJson.encode({'job_id' => job_id}), :status => 200}
      end

      response = @api.post_pig_job_existing_cluster(
        project_name, 
        pigscript_name, 
        git_ref, 
        cluster_id, 
        :parameters => parameters, 
        :project_script_path => project_script_path)
      response.body['job_id'].should == job_id

      response_deprecated = @api.post_job_existing_cluster(
        project_name, 
        pigscript_name, 
        git_ref, 
        cluster_id, 
        :parameters => parameters, 
        :project_script_path => project_script_path)
      response_deprecated.body['job_id'].should == job_id
    end

    it "posts a job for a new cluster, defaulting cluster_type to persistent" do
      job_id = "7b93e4d3ab034188a0c2be418d3d24ed"
      project_name = "my_project"
      pigscript_name = "my_pigscript"
      git_ref = "e20395b8b06fbf52e86665b0660209673f311d1a"
      cluster_size = 5
      cluster_type = Mortar::API::Jobs::CLUSTER_TYPE__PERSISTENT
      body = Mortar::API::OkJson.encode({"project_name" => project_name,
                                         "git_ref" => git_ref,
                                         "cluster_size" => cluster_size,
                                         "cluster_type" => cluster_type,
                                         "parameters" => {},
                                         "notify_on_job_finish" => true,
                                         "job_type" => "pig",
                                         "use_spot_instances" => false,
                                         "pigscript_name" => pigscript_name})
      Excon.stub({:method => :post, :path => "/v2/jobs", :body => body}) do |params|
        {:body => Mortar::API::OkJson.encode({'job_id' => job_id}), :status => 200}
      end
      response = @api.post_pig_job_new_cluster(project_name, pigscript_name, git_ref, cluster_size)
      response.body['job_id'].should == job_id

      response_deprecated = @api.post_job_new_cluster(project_name, pigscript_name, git_ref, cluster_size)
      response_deprecated.body['job_id'].should == job_id
    end

    it "posts a job for a new cluster, defaulting to notify_on_job_finish of true" do
      job_id = "7b93e4d3ab034188a0c2be418d3d24ed"
      project_name = "my_project"
      pigscript_name = "my_pigscript"
      project_script_path = "pigscripts/my_pigscript/"
      git_ref = "e20395b8b06fbf52e86665b0660209673f311d1a"
      cluster_size = 5
      cluster_type = Mortar::API::Jobs::CLUSTER_TYPE__PERSISTENT
      body = Mortar::API::OkJson.encode({"project_name" => project_name,
                                         "git_ref" => git_ref,
                                         "cluster_size" => cluster_size,
                                         "cluster_type" => cluster_type,
                                         "parameters" => {},
                                         "notify_on_job_finish" => true,
                                         "job_type" => "pig",
                                         "use_spot_instances" => false,
                                         "pigscript_name" => pigscript_name,
                                         "project_script_path" => project_script_path,
})
      Excon.stub({:method => :post, :path => "/v2/jobs", :body => body}) do |params|
        {:body => Mortar::API::OkJson.encode({'job_id' => job_id}), :status => 200}
      end
      response = @api.post_pig_job_new_cluster(project_name, pigscript_name, git_ref, cluster_size, :project_script_path => project_script_path)
      response.body['job_id'].should == job_id

      response_deprecated = @api.post_job_new_cluster(project_name, pigscript_name, git_ref, cluster_size, :project_script_path => project_script_path)
      response_deprecated.body['job_id'].should == job_id
    end

    it "accepts non-default params for notify_on_job_finish and use_spot_instances" do
      job_id = "7b93e4d3ab034188a0c2be418d3d24ed"
      project_name = "my_project"
      pigscript_name = "my_pigscript"
      project_script_path = "pigscripts/my_pigscript/"
      git_ref = "e20395b8b06fbf52e86665b0660209673f311d1a"
      cluster_size = 5
      cluster_type = Mortar::API::Jobs::CLUSTER_TYPE__SINGLE_JOB
      body = Mortar::API::OkJson.encode({"project_name" => project_name,
                                         "git_ref" => git_ref,
                                         "cluster_size" => cluster_size,
                                         "cluster_type" => cluster_type,
                                         "parameters" => {},
                                         "notify_on_job_finish" => false,
                                         "job_type" => "pig",
                                         "use_spot_instances" => true,
                                         "pigscript_name" => pigscript_name,
                                         "project_script_path" => project_script_path,
})
      Excon.stub({:method => :post, :path => "/v2/jobs", :body => body}) do |params|
        {:body => Mortar::API::OkJson.encode({'job_id' => job_id}), :status => 200}
      end
      response = @api.post_pig_job_new_cluster(project_name, pigscript_name, git_ref, cluster_size, 
            :cluster_type => cluster_type, :notify_on_job_finish => false, 
            :use_spot_instances => true,
            :project_script_path => project_script_path)
      response.body['job_id'].should == job_id
      response_deprecated = @api.post_job_new_cluster(project_name, pigscript_name, git_ref, cluster_size, 
            :cluster_type => cluster_type, :notify_on_job_finish => false, 
            :use_spot_instances => true,
            :project_script_path => project_script_path)
      response_deprecated.body['job_id'].should == job_id
    end
    
    it "accepts cluster_type of single_job" do
      job_id = "7b93e4d3ab034188a0c2be418d3d24ed"
      project_name = "my_project"
      pigscript_name = "my_pigscript"
      project_script_path = "pigscripts/my_pigscript/"
      git_ref = "e20395b8b06fbf52e86665b0660209673f311d1a"
      cluster_size = 5
      cluster_type = Mortar::API::Jobs::CLUSTER_TYPE__SINGLE_JOB
      body = Mortar::API::OkJson.encode({"project_name" => project_name,
                                         "git_ref" => git_ref,
                                         "cluster_size" => cluster_size,
                                         "cluster_type" => cluster_type,
                                         "parameters" => {},
                                         "notify_on_job_finish" => true,
                                         "job_type" => "pig",
                                         "use_spot_instances" => false,
                                         "pigscript_name" => pigscript_name,
                                         "project_script_path" => project_script_path,
                                        })
      Excon.stub({:method => :post, :path => "/v2/jobs", :body => body}) do |params|
        {:body => Mortar::API::OkJson.encode({'job_id' => job_id}), :status => 200}
      end
      response = @api.post_pig_job_new_cluster(project_name, pigscript_name, git_ref, cluster_size, :cluster_type => cluster_type, :project_script_path => project_script_path)
      response.body['job_id'].should == job_id

      response_deprecated = @api.post_job_new_cluster(project_name, pigscript_name, git_ref, cluster_size, :cluster_type => cluster_type, :project_script_path => project_script_path)
      response_deprecated.body['job_id'].should == job_id
    end

    it "accepts cluster_type of permanent" do
      job_id = "7b93e4d3ab034188a0c2be418d3d24ed"
      project_name = "my_project"
      pigscript_name = "my_pigscript"
      project_script_path = "pigscripts/my_pigscript/"
      git_ref = "e20395b8b06fbf52e86665b0660209673f311d1a"
      cluster_size = 5
      cluster_type = Mortar::API::Jobs::CLUSTER_TYPE__PERMANENT
      body = Mortar::API::OkJson.encode({"project_name" => project_name,
                                         "git_ref" => git_ref,
                                         "cluster_size" => cluster_size,
                                         "cluster_type" => cluster_type,
                                         "parameters" => {},
                                         "notify_on_job_finish" => true,
                                         "job_type" => "pig",
                                         "use_spot_instances" => false,
                                         "pigscript_name" => pigscript_name,
                                         "project_script_path" => project_script_path,
                                        })
      Excon.stub({:method => :post, :path => "/v2/jobs", :body => body}) do |params|
        {:body => Mortar::API::OkJson.encode({'job_id' => job_id}), :status => 200}
      end
      response = @api.post_pig_job_new_cluster(project_name, pigscript_name, git_ref, cluster_size, :cluster_type => cluster_type, :project_script_path => project_script_path)
      response.body['job_id'].should == job_id

      response_deprecated = @api.post_job_new_cluster(project_name, pigscript_name, git_ref, cluster_size, :cluster_type => cluster_type, :project_script_path => project_script_path)
      response_deprecated.body['job_id'].should == job_id
    end

    it "gets a job" do
      job_id = "7b93e4d3ab034188a0c2be418d3d24ed"
      status = Mortar::API::Jobs::STATUS_RUNNING
      Excon.stub({:method => :get, :path => "/v2/jobs/7b93e4d3ab034188a0c2be418d3d24ed"}) do |params|
        {:body => Mortar::API::OkJson.encode({'job_id' => job_id, 'status' => status}), :status => 200}
      end
      response = @api.get_job(job_id)
      response.body['job_id'].should == job_id
      response.body['status'].should == status
    end

    it "gets recent and running jobs" do
      Excon.stub({:method => :get, :path => "/v2/jobs"}) do |params|
        {:body => Mortar::API::OkJson.encode({"jobs" => [{'job_id' => '1', 'status' => 'running'}, {'job_id' => '2', 'status' => 'running'}]}), :status => 200}
      end
      response = @api.get_jobs(0, 10)
      jobs = response.body["jobs"]
      jobs.nil?.should be_false
      jobs.length.should == 2

      response = @api.get_jobs(0, 10, "all")
      jobs = response.body["jobs"]
      jobs.nil?.should be_false
      jobs.length.should == 2

      response = @api.get_jobs(0, 10, "pig")
      jobs = response.body["jobs"]
      jobs.nil?.should be_false
      jobs.length.should == 2

      response = @api.get_jobs(0, 10, "luigi")
      jobs = response.body["jobs"]
      jobs.nil?.should be_false
      jobs.length.should == 2
    end

    it "stops a running job" do
      job_id = "1234abc342221abc"
      Excon.stub({:method => :delete, :path => "/v2/jobs/#{job_id}"}) do |params|
        {:body => Mortar::API::OkJson.encode({"success" => true}), :status => 200}
      end
      response = @api.stop_job(job_id)
      response.body["success"].should be_true
    end
  end
end