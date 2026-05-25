class CreateChatRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_roles do |t|
      t.string :title
      t.text :prompt_description

      t.timestamps
    end
  end
end
