require 'rails_helper'

RSpec.describe Treenode, :type => :model do

  describe "deleted_at" do
    it {should allow_value(nil).for(:deleted_at)}
    it {should allow_value(Time.now).for(:deleted_at)}
  end

  describe "deleted?" do
    context "deleted_at is set" do
      it "should return true" do
        treenode = create(:deleted_treenode)
        expect(treenode.deleted?).to be_truthy
      end
    end
    context "deleted_at is nil" do
      it "should return false" do
        treenode = create(:treenode)
        expect(treenode.deleted?).to be_falsy
      end
    end
  end

  describe "delete" do
    context "a treenode with children" do
      it "should delete all nodes" do
        node = create(:treenode) # Parent node to be deleted
        child = create(:treenode, parent: node) # Child node
        job = create(:job, treenode: child) # Child job

        node.delete

        child = Treenode.unscoped.find(child.id) # Reload child object
        job = Job.unscoped.find(job.id) # Reload job object

        expect(node.deleted?).to be true 
        expect(child.deleted?).to be true
        expect(job.deleted?).to be true
      end
    end
  end

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

  describe "load_state_groups" do
    context "jobs with different states exist" do
      it "should return a hash with states" do
        treenode = create(:top_treenode)
        create(:job, treenode_id: treenode.id, current_flow_step: 10)
        create(:job, treenode_id: treenode.id, current_flow_step: 20)
        hash = treenode.get_state_groups
        expect(hash.size).to eq 2
        expect(hash["START"]).to eq 1
        expect(hash["PROCESS"]).to eq 1
      end
    end
    context "jobs with different states exist under children" do
      it "should return a hash with states" do
        treenode = create(:top_treenode)
        create(:job, treenode_id: treenode.id, current_flow_step: 10)
        create(:job, treenode_id: treenode.id, current_flow_step: 40)
        childnode = create(:treenode, parent_id: treenode.id)
        create(:job, treenode_id: childnode.id, current_flow_step: 10)
        create(:job, treenode_id: childnode.id, current_flow_step: 40)
        hash = treenode.get_state_groups

        expect(hash.size).to eq 2
        expect(hash["PROCESS"]).to eq 2
      end
    end
    context "after node has been moved" do
      it "should return updated hash" do
        treenode = create(:top_treenode)
        treenode2 = create(:top_treenode)
        create(:job, treenode_id: treenode.id, current_flow_step: 10)
        create(:job, treenode_id: treenode.id, current_flow_step: 40)
        childnode = create(:treenode, parent_id: treenode.id)
        create(:job, treenode_id: childnode.id, current_flow_step: 10)
        create(:job, treenode_id: childnode.id, current_flow_step: 40)

        childnode.update_attribute('parent_id', treenode2.id)
        childnode.save
        treenode2 = Treenode.find(treenode2.id)
        tnHash = treenode.get_state_groups
        tn2Hash = treenode2.get_state_groups

        expect(tn2Hash.size).to eq 2
        expect(tn2Hash["START"]).to eq 1
        expect(tnHash.size).to eq 2
        expect(tnHash["START"]).to eq 1
      end
    end
  end
end
