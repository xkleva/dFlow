require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

RSpec.describe Treenode, :type => :model do
    before :each do
		config_init
	end

	describe "name" do
		context "name is empty" do
			treenode = Treenode.new(name: "", parent_id: 1)
			it "should invalidate object" do
				expect(treenode.valid?).to be false
			end
			it "should return a validation error for field name" do
				expect(treenode.errors.messages[:name]).to_not be nil
			end
		end
		context "name is properly formatted" do
			treenode = Treenode.new(name: "Tree Node", parent_id: 1)
			it "should validate object" do
				expect(treenode.valid?).to be true
			end
		end
	end

end
