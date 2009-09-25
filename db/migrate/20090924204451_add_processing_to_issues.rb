class AddProcessingToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :processing, :boolean, :default => true
  end

  def self.down
    remove_column :issues, :processing
  end
end
