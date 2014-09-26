class DoccoController < ApplicationController
  def index
    # 1. github の URL からリポジトリパスを抽出
    username = params[:username]
    repository = params[:repository]
    user_dir = Rails.root.join "tmp", "gicco", username
    dist_path = user_dir + repository
    FileUtils.mkdir_p user_dir.to_s

    if dist_path.exist?

    else
      # 2. github repository のクローン
      command = "git clone https://github.com/#{username}/#{repository}.git #{dist_path}"
      result = `#{command}`
    end

    # js ファイル以外は github にリダイレクト
    format = params[:format]
    show_github and return unless format == "js"

    # 4. js ファイルを抽出
    path = params[:path].gsub "blob/master/", ""

    jsfile = dist_path + "#{path}.#{format}"

    render json: {}, status: 404 and return unless jsfile.exist?

    # TODO: js ファイルの coffee 変換
    # 5. docco で coffee を解析→ドキュメント作成
    doc_path = Rails.root.join 'tmp', 'docs', username, repository
    FileUtils.mkdir_p doc_path

    output_path = File.join doc_path, "#{path}.#{format}"
    docco_result = `docco #{jsfile} -o #{output_path}`

    html_path = File.join(output_path, "#{File.basename(path)}.html")

    data = File.read html_path
    data.gsub! 'href="docco.css"', 'href="/assets/docco.css"'

    send_data data, :disposition => 'inline', :type => 'text/html'
  end


  def show_github
    redirect_to "https://github.com/#{params[:username]}/#{params[:repository]}/#{params[:path]}.#{params[:format]}"
  end

end
