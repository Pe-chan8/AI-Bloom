# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Posts", type: :request do
  let(:user) { create_user }
  let(:other_user) { create_user }

  let!(:post_record) do
    create(
      :post,
      user: user,
      title: "編集前タイトル",
      posted_at: Time.zone.parse("2026-03-16 10:00:00")
    )
  end

  let!(:other_users_post) do
    create(
      :post,
      user: other_user,
      title: "他人の投稿",
      posted_at: Time.zone.parse("2026-03-15 10:00:00")
    )
  end

  let(:valid_params) do
    {
      post: {
        title: "編集後タイトル",
        mood: post_record.mood,
        visibility: post_record.visibility,
        posted_at: post_record.posted_at,
        category: post_record.category,
        subcategory: post_record.subcategory,
        tag_list: [ "前向き" ]
      }
    }
  end

  let(:invalid_params) do
    {
      post: {
        title: "",
        mood: post_record.mood,
        visibility: post_record.visibility,
        posted_at: post_record.posted_at,
        category: post_record.category,
        subcategory: post_record.subcategory,
        tag_list: [ "前向き" ]
      }
    }
  end

  describe "GET /posts" do
    subject { get posts_path }

    context "ログイン済みの場合" do
      before { login_as(user) }

      it "正常にレスポンスを返す" do
        subject
        expect(response).to have_http_status(:ok)
      end

      it "自分の投稿一覧が表示対象になる" do
        subject
        expect(response.body).to include("編集前タイトル")
      end
    end

    context "未ログインの場合" do
      it_behaves_like "未ログイン時にログイン画面へリダイレクトされる"
    end
  end

  describe "GET /posts/:id/edit" do
    context "ログイン済みの場合" do
      before { login_as(user) }

      context "自分の投稿の場合" do
        subject { get edit_post_path(post_record) }

        it "編集画面を表示できる" do
          subject
          expect(response).to have_http_status(:ok)
        end
      end

      context "他人の投稿の場合" do
        subject { get edit_post_path(other_users_post) }

        it "表示できない" do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "未ログインの場合" do
      subject { get edit_post_path(post_record) }

      it_behaves_like "未ログイン時にログイン画面へリダイレクトされる"
    end
  end

  describe "PATCH /posts/:id" do
    context "ログイン済みの場合" do
      before { login_as(user) }

      context "自分の投稿の場合" do
        subject { patch post_path(post_record), params: valid_params }

        it "有効な値なら投稿を更新できる" do
          subject

          expect(response).to have_http_status(:see_other)
          expect(post_record.reload.title).to eq("編集後タイトル")
          expect(post_record.tags_text).to eq("前向き")
        end

        it "更新後はbuddy_talk_topic_pathへリダイレクトする" do
          subject
          expect(response).to redirect_to(buddy_talk_topic_path(post_record))
        end
      end

      context "他人の投稿の場合" do
        subject { patch post_path(other_users_post), params: valid_params }

        it "更新できない" do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "未ログインの場合" do
      subject { patch post_path(post_record), params: valid_params }

      it_behaves_like "未ログイン時にログイン画面へリダイレクトされる"
    end
  end

  describe "DELETE /posts/:id" do
    context "ログイン済みの場合" do
      before { login_as(user) }

      context "自分の投稿の場合" do
        let!(:target_post) { create(:post, user: user) }

        it "削除できる" do
          expect do
            delete post_path(target_post)
          end.to change(Post, :count).by(-1)

          expect(response).to redirect_to(posts_path)
        end
      end

      context "他人の投稿の場合" do
        it "削除できない" do
          expect do
            delete post_path(other_users_post)
          end.not_to change(Post, :count)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "未ログインの場合" do
      subject { delete post_path(post_record) }

      it_behaves_like "未ログイン時にログイン画面へリダイレクトされる"
    end
  end
end
