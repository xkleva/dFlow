require 'rails_helper'

RSpec.describe Treenode, :type => :model do

  describe "name" do
    it {should validate_presence_of(:name)}
    it {should allow_value('a').for(:name)}
    it {should_not allow_value('!@*#&*&@').for(:name)}
    it {should allow_value('@*(a*&').for(:name)}

    context "name is not unique for parent" do
      it "should invalidate object" do
        sibling = create(:child_treenode)
        treenode = Treenode.new(name: sibling.name, parent_id: sibling.parent_id)
        expect(treenode.valid?).to be false
        expect(treenode.errors.messages[:name]).to_not be nil
      end
    end
    context "name is the same as old name" do
      it "should validate object" do
        treenode = create(:treenode)
        expect(treenode.valid?).to be true
      end
    end

    context "parent_id is in a valid position" do
      it "should allow changing parent_id to anywhere outside itself and subnodes of self" do
        root2 = create(:top_treenode)
        child = create(:child_treenode)
        child.parent_id = root2.id
        expect(child.save).to be_truthy
      end
      it "should deny changing parent_id to self" do
        child = create(:child_treenode)
        child.parent_id = child.id
        expect(child.save).to be_falsey
      end
      it "should deny changing parent_id to subnode of self" do
        parent = create(:treenode)
        child = create(:treenode, parent: parent)
        parent.parent_id = child.id
        expect(parent.save).to be_falsey
      end
    end
  end
  describe "children" do
    it {should have_many(:children)}
  end

  describe "breadcrumb" do
    context "multiple parents exist" do
      it "should return a list of objects" do
        treenode = build(:grandchild_treenode)
        expect(treenode.breadcrumb).to_not be nil
      end
      it "should return more than one object" do
        treenode = build(:grandchild_treenode)
        expect(treenode.breadcrumb.size).to eq 2
      end
    end
    context "no parent exists" do
      it "should return an empty list" do
        treenode = build(:top_treenode)
        expect(treenode.breadcrumb.empty?).to be true
      end
    end
    context "as_string flag is set" do
      it "should return a string object" do
        treenode = build(:grandchild_treenode)
        bc = treenode.breadcrumb(as_string: true)
        expect(bc).to be_a(String)
        expect(bc.length > 5).to be true
      end
    end
  end
end
