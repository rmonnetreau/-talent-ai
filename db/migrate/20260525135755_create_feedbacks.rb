class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :feedbacks do |t|
      t.integer :global_score
      t.text :strengths
      t.text :weaknesses
      t.text :best_answer
      t.text :worst_answer
      t.text :priority_advice
      t.text :recommended_method
      t.references :chat, null: false, foreign_key: true

      t.timestamps
    end
  end
end
