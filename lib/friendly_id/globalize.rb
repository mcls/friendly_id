require "i18n"

module FriendlyId

=begin

== Translate slug db column using Globalize

The {FriendlyId::Globalize Globalize} module allow to use
Globalize (https://github.com/svenfuchs/globalize3) to translate slugs.

In order to use this module, your model must have a slug column and set the
field +slug+ translable with Globalize:

    class Post < ActiveRecord::Base
      translates :title, :slug
      extend FriendlyId
      friendly_id :title, :use => :globalize
    end

=== Finds

Finds will take into consideration the current locale:

  I18n.locale = :it
  Post.find("guerre-stellari")
  I18n.locale = :en
  Post.find("star-wars")

To find a slug by an explicit locale, perform the find inside a block
passed to I18n's +with_locale+ method:

  I18n.with_locale(:it) do
    Post.find("guerre-stellari")
  end

=== Creating Records

When new records are created, the slug is generated for the current locale only.

=== Translating Slugs

To translate an existing record's friendly_id, simply change locale and assign
+slug+ field:

  I18n.with_locale(:it) do
    post.slug = "guerre-stellari"
  end

=end
  module Globalize

    def self.included(model_class)
      model_class.instance_eval do
        friendly_id_config.use :slugged
        relation_class.send :include, FinderMethods
        include Model
      end
    end

    module Model
      def slug=(text)
        set_slug(normalize_friendly_id(text))
      end
    end

    module FinderMethods
      protected
      # FriendlyId overrides this method to make it possible to use friendly id's
      # identically to numeric ids in finders.
      #
      # @example
      #  person = Person.find(123)
      #  person = Person.find("joe")
      #
      # @see FriendlyId::ObjectUtils
      def find_one(id)
        return super if id.unfriendly_id?
        unless respond_to?('translated?')
          where(@klass.friendly_id_config.query_field => id).first or super
        else
          where(@klass.friendly_id_config.query_field => id).first or
          joins(:translations).where("#{@klass.downcase}_translations.locale = ? AND #{@klass.downcase}_translations.#{@klass.friendly_id_config.query_field} = ?", I18n.locale, id).first or
          # if locale is not translated fallback to default locale
          joins(:translations).where("#{@klass.downcase}_translations.locale = ? AND #{@klass.downcase}_translations.#{@klass.friendly_id_config.query_field} = ?", I18n.default_locale, id).first or
          super
        end
      end

    end
  end
end
