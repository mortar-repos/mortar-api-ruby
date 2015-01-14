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

module Mortar
  class API
    
    module Clusters
      STATUS_PENDING    = "pending"
      STATUS_STARTING   = "starting"
      STATUS_STARTING_REQUESTED_STOP = "starting_requested_stop"
      STATUS_RUNNING    = "running"
      STATUS_STOPPING   = "stopping"
      STATUS_DESTROYED  = "destroyed"
      STATUS_FAILED     = "failed"
    end
    
    # GET /vX/clusters
    def get_clusters(cluster_backend=Mortar::API::Jobs::CLUSTER_BACKEND__EMR_HADOOP_1)
      request(
        :expects  => 200,
        :idempotent => true,
        :method   => :get,
        :path     => "#{versioned_path("/clusters")}",
        :query    => {:cluster_backend => cluster_backend}
      )
    end 
    
      # DELETE /v2/clusters/:cluster_id
      def stop_cluster(cluster_id)
        request(
          :expects => 200,
          :idempotent => true,
          :method  => :delete,
          :path    => versioned_path("/clusters/#{cluster_id}")
        )
      end   
  end
end
