# frozen_string_literal: true

require_relative "../model"

class GithubInstallation < Sequel::Model
  many_to_one :project
  one_to_many :runners, key: :installation_id, class: :GithubRunner
  one_to_many :repositories, key: :installation_id, class: :GithubRepository

  include ResourceMethods

  def total_active_runner_vcpus
    runners_dataset
      .left_join(:strand, id: :id)
      .exclude(Sequel[:strand][:label] => ["start", "wait_concurrency_limit"])
      .select_map(Sequel[:github_runner][:label])
      .sum do
        label = Github.runner_labels[it]
        Validation.validate_vm_size(label["vm_size"], label["arch"]).vcpus
      end
  end
end

# Table: github_installation
# Columns:
#  id                | uuid    | PRIMARY KEY
#  installation_id   | bigint  | NOT NULL
#  name              | text    | NOT NULL
#  type              | text    | NOT NULL
#  project_id        | uuid    |
#  cache_enabled     | boolean | NOT NULL DEFAULT true
#  use_docker_mirror | boolean | NOT NULL DEFAULT false
# Indexes:
#  github_installation_pkey | PRIMARY KEY btree (id)
# Foreign key constraints:
#  github_installation_project_id_fkey | (project_id) REFERENCES project(id)
# Referenced By:
#  github_repository | github_repository_installation_id_fkey | (installation_id) REFERENCES github_installation(id)
#  github_runner     | github_runner_installation_id_fkey     | (installation_id) REFERENCES github_installation(id)
