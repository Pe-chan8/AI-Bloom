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
        tag_list: [ "前向き", "がんばった" ]
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
    context "ログイン済みの場合" do
      before { login_as(user) }

      it "正常にレスポンスを返す" do
        get posts_path
        expect(response).to have_http_status(:ok)
      end

      it "自分の投稿一覧が表示対象になる" do
        get posts_path
        expect(response.body).to include("編集前タイトル")
      end
    end

    context "未ログインの場合" do
      it "ログインページへリダイレクトされる" do
        get posts_path
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe "GET /posts/:id/edit" do
    context "ログイン済みの場合" do
      before { login_as(user) }

      it "自分の投稿の編集画面は表示できる" do
        get edit_post_path(post_record)
        expect(response).to have_http_status(:ok)
      end

      it "他人の投稿の編集画面は表示できない" do
        get edit_post_path(other_users_post)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "ログインページへリダイレクトされる" do
        get edit_post_path(post_record)
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe "PATCH /posts/:id" do
    context "ログイン済みの場合" do
      before { login_as(user) }

      it "有効な値なら投稿を更新できる" do
        patch post_path(post_record), params: valid_params

        expect(response).to have_http_status(:see_other)
        expect(post_record.reload.title).to eq("編集後タイトル")
        expect(post_record.tags_text).to eq("前向き, がんばった")
      end

      it "更新後はbuddy_talk_topic_pathへリダイレクトする" do
        patch post_path(post_record), params: valid_params

        expect(response).to redirect_to(buddy_talk_topic_path(post_record))
      end

      it "他人の投稿は更新できない" do
        patch post_path(other_users_post), params: valid_params
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "ログインページへリダイレクトされる" do
        patch post_path(post_record), params: valid_params
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe "DELETE /posts/:id" do
    context "ログイン済みの場合" do
      before { login_as(user) }

      it "自分の投稿を削除できる" do
        target_post = create(:post, user: user)

        expect do
          delete post_path(target_post)
        end.to change(Post, :count).by(-1)

        expect(response).to redirect_to(posts_path)
      end

      it "他人の投稿は削除できない" do
        expect do
          delete post_path(other_users_post)
        end.not_to change(Post, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "ログインページへリダイレクトされる" do
        delete post_path(post_record)
        expect(response).to have_http_status(:found)
      end
    end
  end
end
