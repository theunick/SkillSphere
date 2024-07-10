class AddBioToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :bio, :string, default: 'Adoro SkillSphere'
  end
end

