import js.Browser;
import js.html.InputElement;
import js.html.DivElement;
import js.html.AnchorElement;
import js.html.Element;
import haxe.Http;
import haxe.Json;
import StringTools;

class Main {
    static var result:DivElement;

    static function main() {
        var input:InputElement = cast Browser.document.getElementById("search");
        var button:Element = Browser.document.getElementById("btn");
        result = cast Browser.document.getElementById("result");

        // ボタンクリック
        button.onclick = function(_) {
            search(input.value);
        };

        // Enterキーでも検索（onkeydown の方が安定）
        input.onkeydown = function(e:Dynamic) {
            if (e != null && (e.key == "Enter" || e.keyCode == 13)) {
                search(input.value);
            }
        };
    }

    static function search(query:String) {
        if (query == null || query == "") return;

        var url = "https://ja.wikipedia.org/w/api.php?action=query&list=search&format=json&origin=*&srsearch=" + StringTools.urlEncode(query);

        var http = new Http(url);

        http.onData = function(data:String) {
            // JSON を Dynamic としてパース
            var json:Dynamic = Json.parse(data);

            // search は型が固定されていないので Dynamic の配列として扱う
            var searchResults:Array<Dynamic> = [];
            try {
                if (json != null && json.query != null && json.query.search != null) {
                    searchResults = json.query.search;
                }
            } catch (e:Dynamic) {
                // パースやアクセスで問題があれば空配列にする
                searchResults = [];
            }

            result.innerHTML = "<h2>検索結果</h2>";

            for (item in searchResults) {
                // snippet が存在するかチェック
                var rawSnippet:String = "";
                if (item != null && item.snippet != null) rawSnippet = item.snippet;
                var snippet = cleanSnippet(rawSnippet);

                var title:String = "";
                if (item != null && item.title != null) title = item.title;

                addResult(title, snippet);
            }
        };

        http.onError = function(e) {
            result.innerHTML = "エラー: " + e;
        };

        http.request();
    }

    static function cleanSnippet(snippet:String):String {
        if (snippet == null) return "";
        snippet = StringTools.replace(snippet, "<span class=\"searchmatch\">", "");
        snippet = StringTools.replace(snippet, "</span>", "");
        // Wikipedia のスニペットは HTML 断片なのでタグを除去しておく（簡易）
        snippet = StringTools.replace(snippet, "&lt;", "<");
        snippet = StringTools.replace(snippet, "&gt;", ">");
        return snippet;
    }

    static function addResult(title:String, snippet:String) {
        // container を作成
        var container:DivElement = cast Browser.document.createElement("div");

        // リンクを作成
        var link:AnchorElement = cast Browser.document.createElement("a");
        link.href = "https://ja.wikipedia.org/wiki/" + StringTools.urlEncode(title);
        link.target = "_blank";
        link.innerText = title;

        // 説明（innerText で安全に）
        var desc:DivElement = cast Browser.document.createElement("div");
        desc.innerText = snippet;

        container.appendChild(link);
        container.appendChild(desc);

        // スタイル
        var s = container.style;
        s.border = "1px solid #ccc";
        s.margin = "8px";
        s.padding = "8px";
        s.borderRadius = "6px";

        result.appendChild(container);
    }
}
