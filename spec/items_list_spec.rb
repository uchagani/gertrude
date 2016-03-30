require_relative 'spec_helper'

describe 'items list' do
  let(:item_list) { ItemsList.new }
  let(:item) { {'danny7' => {'user_name' => 'danny9', 'rep_id' => '100014624', 'profile_id' => '8192'}} }

  before(:each) do
    item_list.items = {'admin' =>
                           {'danny7' => {'user_name' => 'danny9', 'rep_id' => '100014620', 'profile_id' => '8190', ItemsList::RESERVE_KEY.to_sym => false},
                            'johnny5' => {'user_name' => 'danny7', 'rep_id' => '100014624', 'profile_id' => '8192', ItemsList::RESERVE_KEY.to_sym => false}}}
  end

  describe '#unique_keys_across_items' do
    it 'should raise Item Type Not Defined' do
      expect { item_list.get_item(:blah, 1) }.to raise_error(ItemError::ItemTypeNotDefined)
    end

    it 'should return true if unique keys' do
      expect(item_list.unique_keys_across_items?(item_list.items)).to be true
    end

    it 'should return false if duplicate keys' do
      item_list.items.merge!({'basic' => {'danny7' => {'user_name' => 'danny7'}}})
      expect(item_list.unique_keys_across_items?(item_list.items)).to be false
    end
  end

  describe '#get_item' do
    it 'should raise an error if type not defined' do
      expect { item_list.get_item('foo', 0.01) }.to raise_error ItemError::ItemTypeNotDefined
    end

    it 'should return an item' do
      allow(item_list).to receive(:loop_for_item).with('admin', 0.01).and_return(item)
      expect(item_list.get_item('admin', 0.01)).to eql item
    end
  end

  describe '#release_item' do
    it 'should release an item' do
      item_list.items['admin']['danny7'][ItemsList::RESERVE_KEY] = true
      expect(item_list.release_item('danny7')).to be false
      expect(item_list.items['admin']['danny7'][ItemsList::RESERVE_KEY]).to be false
    end

    it('should raise Invalid Item error when trying to release non reserved item') do
      expect { item_list.release_item('foo') }.to raise_error(ItemError::InvalidItem)
    end
  end

  describe '#get_reserved_items' do
    it 'should return a string of reserved items' do
      allow(item_list).to receive(:reserved_items).and_return(%w(danny7 johnny5))
      expect(item_list.get_reserved_items).to eql 'danny7, johnny5'
    end
  end

  describe '#release_all_items' do
    it 'should release all items' do
      allow(item_list).to receive(:reserved_items).and_return(['danny7'])
      item_list.items['admin']['danny7'][ItemsList::RESERVE_KEY] = true
      item_list.items['admin']['johnny5'][ItemsList::RESERVE_KEY] = true
      item_list.release_all_items
      expect(item_list.items['admin']['danny7'][ItemsList::RESERVE_KEY]).to be false
      expect(item_list.items['admin']['johnny5'][ItemsList::RESERVE_KEY]).to be false
    end

    it 'should return message that all items are released' do
      item_list.items['admin']['danny7'][ItemsList::RESERVE_KEY] = true
      expect(item_list.release_all_items).to eql 'All Items Released.'
    end

    it('should raise No Reserved Items if no items are reserved') do
      expect { item_list.release_all_items }.to raise_error(ItemError::NoReservedItems)
    end
  end

  describe '#reserved_items' do
    it 'should return an array of reserved items' do
      item_list.items['admin']['danny7'][ItemsList::RESERVE_KEY] = true
      expect(item_list.reserved_items).to eql ['danny7']
    end
  end

  describe '#loop_for_item' do
    it 'should reserve an item' do
      allow(item_list).to receive(:get_available_item).with('admin').and_return(item)
      allow(item_list).to receive(:reserve_item).with('admin', 'danny7').and_return(item_list.items['admin']['danny7'][ItemsList::RESERVE_KEY] = true)
      allow(item_list).to receive(:sanitize_response).with(item)
      item_list.loop_for_item('admin', 0.01)
      expect(item_list.items['admin']['danny7'][ItemsList::RESERVE_KEY]).to be true
    end

    it 'should return a sanitized response' do
      allow(item_list).to receive(:get_available_item).with('admin').and_return(item)
      allow(item_list).to receive(:reserve_item).with('admin', 'danny7')
      allow(item_list).to receive(:sanitize_response).with(item).and_return(item)
      expect(item_list.loop_for_item('admin', 0.01)['danny7'].keys).to_not include ItemsList::RESERVE_KEY
    end

    it 'should return a hash' do
      allow(item_list).to receive(:get_available_item).with('admin').and_return(item)
      allow(item_list).to receive(:reserve_item).with('admin', 'danny7')
      allow(item_list).to receive(:sanitize_response).with(item).and_return(item)
      expect(item_list.loop_for_item('admin', 0.01)).to be_a_kind_of Hash
    end

    it 'should raise a timeout error if not items available' do
      allow(item_list).to receive(:get_available_item).with('admin').and_return([])
      expect { item_list.loop_for_item('admin', 0.01) }.to raise_error ItemError::NoAvailableItems
    end
  end

  describe '#sanitize_response' do
    it 'should not include reserve key' do
      item = {'danny7' => {'user_name' => 'danny9', 'rep_id' => '100014624', 'profile_id' => '8192', ItemsList::RESERVE_KEY.to_sym => false}}
      expect(item_list.sanitize_response(item)['danny7'].keys).to_not include ItemsList::RESERVE_KEY
    end
  end

  describe '#reserve_item' do
    it 'should reserve an item' do
      expect(item_list.reserve_item('admin', 'danny7')).to be true
      expect(item_list.items['admin']['danny7'][ItemsList::RESERVE_KEY]).to be true
    end
  end

  describe '#get_available_item' do
    it 'should get next available item' do
      item_list.items['admin']['danny7'][ItemsList::RESERVE_KEY] = true
      expect(item_list.get_available_item('admin')).to eql({"johnny5" => {"user_name" => "danny7", "rep_id" => "100014624", "profile_id" => "8192", ItemsList::RESERVE_KEY.to_sym => false}})
    end
  end
end