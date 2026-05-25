class CreateChats < ActiveRecord::Migration[8.1]
  def change
    create_table :chats do |t|
      t.string :title
      t.references :interview, null: false, foreign_key: true
      t.references :chat_role, null: false, foreign_key: true

      t.timestamps
    end
  end
end
