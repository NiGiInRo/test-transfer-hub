class CreateTransfers < ActiveRecord::Migration[7.2]
  def change
    create_table :transfers do |t|
      t.integer :user_id, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :idempotency_key, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :transfers, :idempotency_key, unique: true
  end
end
