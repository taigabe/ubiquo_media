require File.dirname(__FILE__) + "/../../test_helper"

class UbiquoMedia::Connectors::I18nTest < ActiveSupport::TestCase

  I18n = UbiquoMedia::Connectors::I18n

  if Ubiquo::Plugin.registered[:ubiquo_i18n]

    def setup
      save_current_connector(:ubiquo_media)
      I18n.load!
      define_translatable_test_model
    end

    def teardown
      reload_old_connector(:ubiquo_media)
    end

    test 'uhook_create_asset_relations_table_should_create_table' do
      ActiveRecord::Migration.expects(:create_table).with(:asset_relations, :translatable => true)
      ActiveRecord::Migration.uhook_create_asset_relations_table {}
    end

    test 'uhook_default_values_in_asset_relations_should_the_locale_if_related_object_is_translatable' do
      object = UbiquoMedia::TestModel.new :locale => 'jp'
      assert_equal({:locale => 'jp'}, AssetRelation.uhook_default_values(object, nil))
    end

    test 'uhook_default_values_in_asset_relations_should_empty_hash_if_related_object_is_not_translatable' do
      assert_equal({}, AssetRelation.uhook_default_values(Asset.new, nil))
    end

    test 'uhook_filtered_search_in_asset_relations_should_yield_with_locale_filter' do
      AssetRelation.expects(:all)
      AssetRelation.expects(:with_scope).with(:find => {:conditions => ["asset_relations.locale <= ?", 'ca']}).yields
      AssetRelation.uhook_filtered_search({:locale => 'ca'}) { AssetRelation.all }
    end

    test 'uhook_media_attachment should add translation_shared option if set' do
      Asset.class_eval do
        media_attachment :simple
      end
      Asset.uhook_media_attachment :simple, {:translation_shared => true}

      reflection = Asset.reflections[:simple]
      assert  reflection.is_translation_shared?
      assert !reflection.is_translation_shared_on_initialize?

      asset_relations_reflection = Asset.reflections[:simple_asset_relations]
      assert  asset_relations_reflection.is_translation_shared?
      assert !asset_relations_reflection.is_translation_shared_on_initialize?
    end

    test 'uhook_media_attachment should add translation_shared_on_initialize option if set' do
      Asset.class_eval do
        media_attachment :simple
      end

      Asset.uhook_media_attachment :simple, {:translation_shared_on_initialize => true}

      reflection = Asset.reflections[:simple]
      assert  reflection.is_translation_shared_on_initialize?
      assert !reflection.is_translation_shared?

      asset_relations_reflection = Asset.reflections[:simple_asset_relations]
      assert  asset_relations_reflection.is_translation_shared_on_initialize?
      assert !asset_relations_reflection.is_translation_shared?
    end

    test 'uhook_media_attachment should not add translation_shared option if not set' do
      Asset.class_eval do
        media_attachment :simple
      end
      Asset.uhook_media_attachment :simple, {:translation_shared => false}

      reflection = Asset.reflections[:simple]
      assert !reflection.is_translation_shared?
      assert !reflection.is_translation_shared_on_initialize?

      asset_relations_reflection = Asset.reflections[:simple_asset_relations]
      assert !asset_relations_reflection.is_translation_shared?
      assert !asset_relations_reflection.is_translation_shared_on_initialize?

    end

    test 'should not share attachments between translations if not defined' do
      UbiquoMedia::TestModel.class_eval do
        unshare_translations_for :photo
        media_attachment :photo, :translation_shared => false
      end

      # FIXME: this test makes trouble on UbiquoMedia::MediaSelector::ActiveRecord
      # valid_asset_types_in_* complaining that it has an AssetRelation with a non-existing asset.
      # To reproduce that go to the mentioned class and comment the FIXME too
      instance = UbiquoMedia::TestModel.create :locale => 'ca'
      translated_instance = instance.translate('en')
      translated_instance.save

      instance.photo << create_image
      assert_equal 0, translated_instance.reload.photo.size
    end

    test 'should share attachments between translations when defined' do
      UbiquoMedia::TestModel.class_eval do
        media_attachment :photo, :translation_shared => true
      end

      instance = UbiquoMedia::TestModel.create :locale => 'ca'
      translated_instance = instance.translate('en')
      translated_instance.save

      instance.photo << create_image
      assert_equal 1, translated_instance.reload.photo.size
    end

    test 'should not share attachments for the main :asset_relations reflection' do
      UbiquoMedia::TestModel.class_eval do
        media_attachment :photo, :translation_shared => true
      end

      assert !UbiquoMedia::TestModel.reflections[:asset_relations].is_translation_shared?
    end

    test 'should ony display the specific media attachment and not all of them' do
      UbiquoMedia::TestModel.class_eval do
        media_attachment :photo, :translation_shared => true
        media_attachment :video, :translation_shared => true
      end

      Locale.current = 'ca'
      instance = UbiquoMedia::TestModel.create :locale => 'ca'
      instance.photo << photo = create_image
      instance.save

      assert_equal photo, instance.photo.first
      assert_equal photo, instance.reload.photo.first

      # this fails cause instance.video == instance.photo
      assert instance.video.blank?
      assert instance.reload.video.blank?
      assert instance.reload.video.reload.blank?
      assert instance.video.blank?
    end

    test 'should not duplicate asset relations with different content_id when assigning directly' do
      UbiquoMedia::TestModel.class_eval do
        media_attachment :gallery, :translation_shared => true
      end

      Locale.current = 'ca'
      instance = UbiquoMedia::TestModel.create :locale => 'ca'
      2.times do
        instance.gallery << AssetPublic.create(:resource => Tempfile.new('tmp'), :name => 'gallery')
      end

      instance.save
      Locale.current = 'en'
      translation = instance.translate('en')
      translation.gallery # load the association, required to recreate the bug
      translation.save
      assert_equal 2, translation.reload.gallery.size
    end

    test 'should share attachments between translations when assignating' do
      UbiquoMedia::TestModel.class_eval do
        media_attachment :photo, :translation_shared => true
      end

      instance = UbiquoMedia::TestModel.create :locale => 'ca'
      translated_instance = instance.translate('en')
      translated_instance.save

      instance.photo = [create_image]
      assert_equal 1, translated_instance.reload.photo.size
    end

    test 'should only update asset relation name in one translation' do
      UbiquoMedia::TestModel.class_eval do
        media_attachment :photo, :translation_shared => true
      end

      Locale.current = 'ca'
      instance = UbiquoMedia::TestModel.create :locale => 'ca'
      translated_instance = instance.translate('en')
      translated_instance.save
      instance.photo << photo = create_image

      # save the original name in the translation and then update it
      original_name = AssetRelation.name_for_asset :photo, translated_instance.reload.photo.first, translated_instance

      Locale.current = 'en'
      translated_instance.photo_attributes = [{
        "id" => translated_instance.photo_asset_relations.first.id.to_s,
        "asset_id" => photo.id.to_s,
        "name" => 'newname'
      }]
      translated_instance.save

      # name successfully changed
      assert_equal 'newname', translated_instance.name_for_asset(:photo, photo)
      # translation untouched
      assert_equal original_name, instance.name_for_asset(:photo, photo)
    end

    test 'should create a translated asset relation when the object is really new' do
      # it might happen in a controller that asset relations are assigned before
      # the content_id, so this situation must be under control
      UbiquoMedia::TestModel.class_eval do
        media_attachment :photo, :translation_shared => true
      end

      Locale.current = 'ca'
      instance = UbiquoMedia::TestModel.create :locale => 'ca'
      instance.photo << photo = create_image
      translated_instance = instance.translate('en')
      translated_instance.content_id = nil

      # save the original name in the translation and then update it
      original_name = AssetRelation.name_for_asset :photo, photo, translated_instance

      Locale.current = 'en'
      translated_instance.photo_attributes = [{
        "id" => instance.photo_asset_relations.first.id.to_s,
        "asset_id" => photo.id.to_s,
        "name" => 'newname'
      }]
      translated_instance.content_id = instance.content_id
      translated_instance.save

      # name successfully changed
      assert_equal 'newname', translated_instance.name_for_asset(:photo, photo)
      # translation untouched
      assert_equal original_name, instance.name_for_asset(:photo, photo)
    end

    test 'should respect original relations when creating new translations if the relation is not shared_translations ' do
      UbiquoMedia::TestModel.class_eval do
        media_attachment :photo, :translation_shared => false,
                                 :translation_shared_on_initialize => true
      end
      #  instance will have versions in ca, en and es
      #    [ca, es]  will have the asset 'photo'
      #    en        will have another   'new_photo'
      #
      #  no relations will be deleted or modified
      #
      Locale.current = 'ca'
      instance = UbiquoMedia::TestModel.create :locale => 'ca'
      instance.photo << photo = create_image

      en_instance = instance.translate('en')
      Locale.current = 'en'

      en_instance.photo_attributes = [{
        "asset_id" => (new_photo = create_image).id.to_s,
      }]
      assert en_instance.save

      assert_equal [new_photo], en_instance.reload.photo
      assert_equal [photo], instance.reload.photo

      Locale.current = 'es'
      es_instance = instance.translate('es')

      es_instance.photo_attributes = [{
        "id" => instance.photo_asset_relations.first.id.to_s,
        "asset_id" => photo.id.to_s,
      }]

      assert es_instance.save

      assert_equal [photo],     es_instance.reload.photo
      assert_equal [new_photo], en_instance.reload.photo
      assert_equal [photo],     instance.reload.photo

      # check that everyone is related
      assert_equal_set [es_instance, en_instance, instance], es_instance.with_translations
    end

    test 'should clean old asset relations when have some new assigned' do
     UbiquoMedia::TestModel.class_eval do
       media_attachment :photo, :translation_shared => true
     end

     Locale.current = 'ca'
     instance = UbiquoMedia::TestModel.create :locale => 'ca'
     t = instance.translate('es')
     assert t.save

     image = create_image
     assert_difference('AssetRelation.count') do
       instance.photo = [image]
     end
     assert_equal [image], t.reload.photo

     relation = instance.photo_asset_relations.first
     relation_translated = relation.translate('es')
     relation_translated.related_object_id = t.id

     assert_difference('AssetRelation.count') do
       relation_translated.save
     end

     Locale.current = nil
     assert_equal [image], t.reload.photo
     assert_equal [relation_translated], t.reload.photo_asset_relations

     assert_equal [image], instance.reload.photo
     assert_equal [relation], instance.reload.photo_asset_relations

     assert_equal relation.reload.related_object_id, instance.id
     assert_equal relation_translated.reload.related_object_id, t.id

     # now the real test
     Locale.current = 'ca'
     instance.reload
     t.reload
     new_image = create_image

     # should delete the two existing AssetRelation and create a new one
     assert_difference('AssetRelation.count', -2 + 1 ) do
       instance.update_attributes :photo_attributes => {
         "2"=>{"name"=>"Imagen 2", "position"=>"1", "asset_id"=>new_image.id}
       }
     end

     assert_equal [new_image], t.reload.photo
     assert_equal [new_image], instance.reload.photo

     assert !AssetRelation.find_by_id(relation.id)
     assert !AssetRelation.find_by_id(relation_translated.id)
    end

    def test_uhook_current_asset_relations
      AssetRelation.destroy_all
      Locale.current = 'ca'
      asset_one, asset_two = create_image, create_image
      model = TestMediaTranslatableModel.create(
        :field1 => 'jaja',
        # is required
        :sized_shared_attributes => [
          {:asset_id => asset_one.id},
          {:asset_id => asset_two.id}
        ],
        :sized_initialized_attributes => [
          {:asset_id => asset_one.id},
          {:asset_id => asset_two.id}
          ]
      )
      relation = AssetRelation.last
      t = relation.translate('es')
      model_translated = model.translate('es')

      # reject the relation recently instanciated as is not persistent
      model_translated.uhook_current_asset_relations([relation, t])
      assert_equal [t], model_translated.uhook_current_asset_relations([relation, t])

      # do not filter anything for assets (or any not translatable class)
      assert_equal [relation.asset, t.asset],
                   model_translated.uhook_current_asset_relations([asset_two, asset_two])

      assert_equal [relation.asset, t.asset],
                    model.uhook_current_asset_relations([asset_two, asset_two])

      # do not filter, no duplicates
      assert_equal [relation, AssetRelation.first],
                    model_translated.uhook_current_asset_relations([relation, AssetRelation.first])

    end

    def test_current_asset_relations_should_consider_the_case_where_it_have_a_new_relation_for_size_validation
      AssetRelation.destroy_all
      asset_one, asset_two = create_image, create_image
      begin
        model = TestMediaTranslatable.create(
          :test_media_translatable_models_attributes =>
            [
              :field1 => 'jaja',
              :sized_shared_attributes => [
                {:asset_id => asset_one.id},
                {:asset_id => asset_two.id}
              ]
          ]
        )

        t = model.translate('de')
        Locale.current = 'de'

        model_with_attachments = TestMediaTranslatableModel.last

        assert t.save

        assert_difference('TestMediaTranslatableModel.count', 1) do
          # we should new create two new asset relations on the new object
          assert_difference('AssetRelation.count', 2) do
            assert t.update_attributes(
              :test_media_translatable_models_attributes =>
                [
                  :field1 => 'jaja translated',
                  :content_id => model.test_media_translatable_models.first.content_id,
                  :sized_shared_attributes => [
                    {:id => model_with_attachments.asset_relations.first.id, :asset_id => asset_one.id, :name => 'another'},
                    {:id => model_with_attachments.asset_relations.last.id, :asset_id => asset_two.id}
                  ]
              ]
            )
          end
        end
        assert model.valid?
        assert_equal t.test_media_translatable_models.first.content_id,
                                     model_with_attachments.content_id

      ensure
        # cleanup
      end
    end

    # old school, ubiquo forms way
    def test_current_asset_relations_should_consider_the_case_where_it_have_a_new_relation_for_size_validation_shit_jajaja_initialize
      #
      #
      # :sized_initialized attachment allows only 1 element

      AssetRelation.destroy_all
      TestMediaTranslatableModel.new.sized_shared.options[:required] = false
      asset_one, asset_two = create_image, create_image
      begin
        Locale.current = 'en'
        model = TestMediaTranslatableModel.create(
          :field1 => 'jaja',
          :sized_initialized_attributes => [
            {:asset_id => asset_one.id},
          ]
        )

        Locale.current = 'de'
        assert_difference('TestMediaTranslatableModel.count', 1) do
          assert_difference('AssetRelation.count', 1) do
            # now ignore 'model' asset, we want a another
            t = TestMediaTranslatableModel.create({
              :field1 => 'jaja translated',
              :content_id => model.content_id,
              :sized_initialized_attributes => [
                {:id => model.asset_relations.first.id, :asset_id => asset_two.id}
              ]})
            # here the validation error, we will have the 'model' asset_relation and the new
            # were are creating, when we (t) should be independent and forget about our translation
            # but we don't have any validation error
            assert !t.errors.on(:sized_initialized)
            assert t.errors.blank?
            assert t.sized_initialized_asset_relations.size == 2
            # we can do this
            assert t.save
            # and all will be just fine, why ????????????????
          end
        end

        assert model.valid?
        assert model.reload.valid?

      ensure
        # cleanup
        TestMediaTranslatableModel.new.sized_shared.options[:required] = true
      end
    end


    private

    def define_translatable_test_model
      unless defined? UbiquoMedia::TestModel
        model = Class.new(ActiveRecord::Base)
        UbiquoMedia.const_set(:TestModel, model)
      end
      UbiquoMedia::TestModel.class_eval do
        set_table_name 'ubiquo_media_test_models'
      end
      unless UbiquoMedia::TestModel.table_exists?
        ActiveRecord::Base.connection.create_table(:ubiquo_media_test_models, :translatable => true) {}
      end
      UbiquoMedia::TestModel.translatable
    end

    def create_image
      AssetPublic.create(:resource => Tempfile.new('tmp'), :name => 'photo')
    end

  else
    puts 'ubiquo_i18n not found, omitting UbiquoMedia::Connectors::I18n tests'
  end
end
