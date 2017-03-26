class CreateMentions < ActiveRecord::Migration[5.0]
  def change
    create_table :mentions do |t|
      t.integer :status_id, limit: 8
      t.timestamps
    end
  end
end
