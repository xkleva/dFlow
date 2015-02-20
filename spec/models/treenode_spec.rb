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
    context "name is nil" do
      treenode = Treenode.new(name: nil, parent_id: 1)
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
    context "name is not unique for parent" do
      treenode = Treenode.new(name: "Barn", parent_id: 1)
      it "should invalidate object" do
        expect(treenode.valid?).to be false
      end
      it "should return a validation error for field 'name'" do
        expect(treenode.errors.messages[:name]).to_not be nil
      end
    end
    context "name is the same as old name" do
      it "should validate object" do
        treenode = Treenode.find(1)
        expect(treenode.valid?).to be true
      end
    end
    context "name contains no alphanumerical character" do
      treenode = Treenode.new(name: "!@#)(", parent_id: 1)
      it "should invalidate object" do
        expect(treenode.valid?).to be false
      end
      it "should return a validation error for field name" do
        expect(treenode.errors.messages[:name]).to_not be nil
      end
    end
    context "parent_id is in a valid position" do
      it "should allow changing parent_id to anywhere outside itself and subnodes of self" do
        root2 = Treenode.create(name: "Toppnod 2")
        child = Treenode.find_by_id(3)
        child.parent_id = root2.id
        expect(child.save).to be_truthy
      end
      it "should deny changing parent_id to self" do
        child = Treenode.find_by_id(3)
        child.parent_id = child.id
        expect(child.save).to be_falsey
      end
      it "should deny changing parent_id to subnode of self" do
        child = Treenode.find_by_id(2)
        child.parent_id = 3
        expect(child.save).to be_falsey
      end
    end
  end
  describe "children" do
    context "children exists" do
      it "should return a list of children" do
        treenode = Treenode.find_by_id(1)
        expect(treenode.children).to_not be nil
        expect(treenode.children.first).to be_a(Treenode)
      end
    end
  end

  describe "breadcrumb" do
    context "multiple parents exist" do
      it "should return a list of objects" do
        treenode = Treenode.find_by_id(3)
        expect(treenode.breadcrumb).to_not be nil
      end
      it "should return more than one object" do
        treenode = Treenode.find_by_id(3)
        expect(treenode.breadcrumb.size).to eq 2
      end
    end
    context "no parent exists" do
      it "should return an empty list" do
        treenode = Treenode.find_by_id(1)
        expect(treenode.breadcrumb.empty?).to be true
      end
    end
    context "as_string flag is set" do
      it "should return a string object" do
        treenode = Treenode.find_by_id(3)
        bc = treenode.breadcrumb(as_string: true)
        expect(bc).to be_a(String)
        expect(bc.length > 5).to be true
      end
    end
  end
end
