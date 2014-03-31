require 'spec_helper'

describe Libertree::Model::Account do
  before :each do
    @account = Libertree::Model::Account.create( FactoryGirl.attributes_for(:account) )
    @member = @account.member
  end

  describe '#messages' do
    it 'returns messages sent and received' do
      other_account = Libertree::Model::Account.create( FactoryGirl.attributes_for(:account) )
      other_member = other_account.member

      message_sent = Libertree::Model::Message.
        create_with_recipients({ :sender_member_id => @member.id,
                                 :recipient_member_ids => [other_member.id],
                                 :text => 'Hello'
                               })
      message_received = Libertree::Model::Message.
        create_with_recipients({ :sender_member_id => other_member.id,
                                 :recipient_member_ids => [@member.id],
                                 :text => 'Bye'
                               })
      message_other = Libertree::Model::Message.
        create_with_recipients({ :sender_member_id => other_member.id,
                                 :recipient_member_ids => [other_member.id],
                                 :text => 'None of your business'
                               })

      expect( @account.messages ).to match_array [message_sent, message_received]
    end
  end

  describe '#delete_cascade' do
    context 'given an account with some posts and other entities' do
      before :each do
        other_account = Libertree::Model::Account.create( FactoryGirl.attributes_for(:account) )
        other_member = other_account.member

        post1 = Libertree::Model::Post.create(
          FactoryGirl.attributes_for( :post, member_id: @member.id, text: 'first post' )
        )
        post2 = Libertree::Model::Post.create(
          FactoryGirl.attributes_for( :post, member_id: other_member.id, text: 'second post' )
        )

        comment1 = Libertree::Model::Comment.create(
          FactoryGirl.attributes_for( :comment, member_id: @member.id, post_id: post2.id, text: 'first comment' )
        )
        comment2 = Libertree::Model::Comment.create(
          FactoryGirl.attributes_for( :comment, member_id: other_member.id, post_id: post2.id, text: 'second comment' )
        )

        @post1_id = post1.id
        @post2_id = post2.id
        @comment1_id = comment1.id
        @comment2_id = comment2.id
        @member_id = @member.id
        @account_id = @account.id
      end

      it 'deletes the account and all subordinate entities belonging to the account, but not entities not belonging to the account' do
        Libertree::Model::Post[@post1_id].should_not be_nil
        Libertree::Model::Post[@post2_id].should_not be_nil
        Libertree::Model::Comment[@comment1_id].should_not be_nil
        Libertree::Model::Comment[@comment2_id].should_not be_nil
        Libertree::Model::Member[@member_id].should_not be_nil
        Libertree::Model::Account[@account_id].should_not be_nil

        @account.delete_cascade

        Libertree::Model::Post[@post1_id].should be_nil
        Libertree::Model::Post[@post2_id].should_not be_nil
        Libertree::Model::Comment[@comment1_id].should be_nil
        Libertree::Model::Comment[@comment2_id].should_not be_nil
        Libertree::Model::Member[@member_id].should be_nil
        Libertree::Model::Account[@account_id].should be_nil
      end
    end
  end
end