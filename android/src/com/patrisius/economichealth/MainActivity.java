package com.patrisius.economichealth;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

/**
 * Economic Health - WebView shell.
 * Loads the single-file dashboard from assets. Universal file-URL access is
 * enabled so the file:// page can fetch https market APIs (Stooq) directly
 * without CORS issues.
 */
public class MainActivity extends Activity {
    private WebView wv;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        wv = new WebView(this);
        WebSettings ws = wv.getSettings();
        ws.setJavaScriptEnabled(true);
        ws.setDomStorageEnabled(true);
        ws.setAllowFileAccess(true);
        ws.setAllowContentAccess(true);
        // Allow the local file:// dashboard to call https APIs (CORS bypass)
        ws.setAllowFileAccessFromFileURLs(true);
        ws.setAllowUniversalAccessFromFileURLs(true);
        ws.setMediaPlaybackRequiresUserGesture(false);
        ws.setLoadWithOverviewMode(true);
        ws.setUseWideViewPort(true);
        // Explicit Chrome-Mobile UA (matches the UA investing.com was verified with)
        // so sites serve the standard mobile page instead of a WebView-specific one.
        ws.setUserAgentString("Mozilla/5.0 (Linux; Android 14; SM-A336E) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36");
        wv.setWebViewClient(new WebViewClient());
        setContentView(wv);
        if (savedInstanceState == null) {
            wv.loadUrl("file:///android_asset/www/index.html");
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        wv.saveState(outState);
    }

    @Override
    protected void onRestoreInstanceState(Bundle savedInstanceState) {
        super.onRestoreInstanceState(savedInstanceState);
        wv.restoreState(savedInstanceState);
    }

    @Override
    public void onBackPressed() {
        // Ask the page to close its topmost overlay (stock detail -> stock list
        // -> IHSG detail); only leave the app when no overlay is open.
        wv.evaluateJavascript(
            "(window.__closeTop ? window.__closeTop() : 'none')",
            v -> {
                if ("\"closed\"".equals(v)) return; // overlay handled it
                if (wv.canGoBack()) wv.goBack();
                else MainActivity.super.onBackPressed();
            });
    }
}
