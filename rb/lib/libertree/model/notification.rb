require 'json'

module Libertree
  module Model
    class Notification < M4DBI::Model(:notifications)
      def account
        @account ||= Account[self.account_id]
      end

      def data
        JSON.parse self['data']
      end

      # RDBI casting not working with TIMESTAMP WITH TIME ZONE ?
      def time_created
        DateTime.parse self['time_created']
      end

      def self.for_account_and_comment_id(account, comment_id)
        self.s(
          %|
            SELECT *
            FROM notifications
            WHERE
              account_id = ?
              AND data = '{"type":"comment","comment_id":#{comment_id.to_i}}'
          |,
          account.id
        )
      end

      def self.for_account_and_post(account, post)
        r = []
        post.likes.each do |like|
          r += self.s(
            %|
              SELECT *
              FROM notifications
              WHERE
                account_id = ?
                AND data = '{"type":"post-like","post_like_id":#{like.id}}'
              LIMIT 1
            |,
            account.id
          )
        end
        r
      end
    end
  end
end
