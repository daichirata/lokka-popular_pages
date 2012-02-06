require 'garb'

module Lokka
  module PopularPages
    def self.registered(app)
      app.get '/admin/plugins/popular_pages' do
        haml :"plugin/lokka-popular_pages/views/index", :layout => :"admin/layout"
      end

      app.put '/admin/plugins/popular_pages' do
        params.each_pair do |k, v|
          Option.send("#{k}=", v)
        end

        flash[:notice] = 'Updated.'
        redirect '/admin/plugins/popular_pages'
      end

      app.helpers do
        def popular_pages(option = {})
          Analytics.response(option).map do |res|
            Entry(res.page_path.sub(/\//, ""))
          end.compact
        end
      end
    end
    module Analytics
      class Upvs
        extend Garb::Model

        metrics :pageviews
        dimensions :page_title, :page_path
      end

      def self.profile
        email    = Option.popular_pages_email
        password = Option.popular_pages_password
        tracker  = Option.popular_pages_tracker

        unless @profile
          Garb::Session.login(email, password)
          @profile = Garb::Management::Profile.all.detect {|p| p.web_property_id == tracker}
        end
        @profile
      end

      def self.response(option)
        default =
          { :limit      => 10,
            :sort       => :pageviews.descending,
            :start_date => (1.month.ago Time.now).beginning_of_month,
            :end_date   => (1.month.ago Time.now).end_of_month }

        profile.upvs(default.merge(option))
      end
    end
  end
end


