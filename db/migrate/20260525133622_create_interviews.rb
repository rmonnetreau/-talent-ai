class CreateInterviews < ActiveRecord::Migration[8.1]
  def change
    create_table :interviews do |t|
      t.string :job_title
      t.text :job_description
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
