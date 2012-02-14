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
          return unless Analytics.valid?

          Analytics.response(option).map do |res|
            Entry(res.page_path.sub(/\//, "")) rescue nil
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

      class << self

        def valid?
          %w(popular_pages_tracker popular_pages_password popular_pages_email).all? do |attr|
            Option.send(attr).present?
          end
        end

        def response(option)
          @config =
            option.delete(:config) || :last_month
          profile.upvs(get_config.merge(option))
        end

        def profile
          if update?
            @profile = if @profile
              Thread.new { _profile }
            else
              _profile
            end
          end
          @profile
        end

        def _profile
          Garb::Session.login(Option.popular_pages_email, Option.popular_pages_password)
          Garb::Management::Profile.all.detect do |prof|
            prof.web_property_id == Option.popular_pages_tracker
          end
        end

        def update?
          unless @time_stamp
            @time_stamp = Time.now
            return true
          end

          case @config.to_s
          when "last_month"
            set_if { (1.month.from_now @time_stamp).beginning_of_month < Time.now }
          when "last_week"
            set_if { (1.week.from_now @time_stamp).beginning_of_week < Time.now }
          end
        end

        def set_if
          @time_stamp = Time.now if yield
        end

        def get_config
          send(@config) rescue last_month
        end

        def last_month
          { :limit      => 10,
            :sort       => :pageviews.descending,
            :start_date => (1.month.ago Time.now).beginning_of_month,
            :end_date   => (1.month.ago Time.now).end_of_month }
        end

        def last_week
          { :limit      => 10,
            :sort       => :pageviews.descending,
            :start_date => (1.week.ago Time.now).beginning_of_week,
            :end_date   => (1.week.ago Time.now).end_of_week }
        end

      end
    end
  end
end


