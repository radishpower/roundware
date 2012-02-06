/*
 	This file is part of RoundwareLib. Originally developed for the
 	Android OS by Rob Knapen, based on earlier work by Dan Latham.
 	
    RoundwareLib is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    RoundwareLib is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with RoundwareLib.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.halseyburgund.roundware.server;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.NameValuePair;
import org.apache.http.client.HttpClient;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.FileBody;
import org.apache.http.entity.mime.content.StringBody;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;
import org.apache.http.protocol.HTTP;

import com.halseyburgund.roundware.util.RWHtmlLog;


/**
 * General HTTP data transfer handler.
 */
public class RWHttpManager {
	
	// debugging
	private final static String TAG = "RWHttpManager";
	private final static boolean D = true;
	
	private final static String POST_MIME_TYPE = "application/x-www-form-urlencoded";
	private final static String HTTP_POST_FAILED = "HTTP POST failed with status: ";	

	private final static int CONNECTION_TIMEOUT_MSEC = 15000; // = 15 sec
	
	
	public static String doGet(String page, Properties props) throws Exception {
		HttpParams httpParams = new BasicHttpParams();
		HttpConnectionParams.setConnectionTimeout(httpParams, CONNECTION_TIMEOUT_MSEC);
		HttpConnectionParams.setSoTimeout(httpParams, CONNECTION_TIMEOUT_MSEC); 
		
		HttpClient httpClient = new DefaultHttpClient(httpParams);

		StringBuilder uriBuilder = new StringBuilder(page);
	
		StringBuffer sbResponse = new StringBuffer ();
		
		Enumeration<Object> enumProps = props.keys();
		String key, value = null;
		
		uriBuilder.append('?');
		
		while (enumProps.hasMoreElements()) {
			key = enumProps.nextElement().toString();
			value = props.get(key).toString();
			uriBuilder.append(key);
			uriBuilder.append('=');
			uriBuilder.append(java.net.URLEncoder.encode(value));
			if (enumProps.hasMoreElements()) {
				uriBuilder.append('&');
			}
		}

		if (D) { RWHtmlLog.i(TAG, "GET request: " + uriBuilder.toString(), null); }
		
		HttpGet request = new HttpGet(uriBuilder.toString());
		HttpResponse response = httpClient.execute(request);

		int status = response.getStatusLine().getStatusCode();

		// we assume that the response body contains the error message
		if (status != HttpStatus.SC_OK) {
			ByteArrayOutputStream ostream = new ByteArrayOutputStream();
			response.getEntity().writeTo(ostream);
			RWHtmlLog.e(TAG, "GET ERROR: " + ostream.toString(), null);
			
			throw new Exception(HTTP_POST_FAILED + status);
			
		} else {
			InputStream content = response.getEntity().getContent();
			BufferedReader reader = new BufferedReader(new InputStreamReader(content));
			String line;
			while ((line = reader.readLine())!=null) {
				sbResponse.append(line);
			}
			content.close(); // this will also close the connection
		}

		if (D) { RWHtmlLog.i(TAG, "GET response: " + sbResponse.toString(), null); }
		
		return sbResponse.toString();
	}

	
	public static String doPost(String page, Properties props) throws Exception
	{
		HttpParams httpParams = new BasicHttpParams();
		HttpConnectionParams.setConnectionTimeout(httpParams, CONNECTION_TIMEOUT_MSEC);
		HttpConnectionParams.setSoTimeout(httpParams, CONNECTION_TIMEOUT_MSEC); 
		
		HttpClient httpClient = new DefaultHttpClient(httpParams);
		
		HttpPost request = new HttpPost(page);
		HttpResponse response = null;
		HttpEntity entity = null;
		  
		StringBuffer sbResponse = new StringBuffer ();
		
		Enumeration<Object> enumProps = props.keys();
		String key, value = null;
		
		 List <NameValuePair> nvps = new ArrayList <NameValuePair>();
		
		while (enumProps.hasMoreElements()) {
			key = (String)enumProps.nextElement();
			value = (String)props.get(key);
			nvps.add(new BasicNameValuePair(key, value));
		}
		
		UrlEncodedFormEntity uf = new UrlEncodedFormEntity(nvps, HTTP.UTF_8);
		request.setEntity(uf);
		request.setHeader("Content-Type", POST_MIME_TYPE);
		
         // Post, check and show the result (not really spectacular, but works):
         response = httpClient.execute(request);
         entity = response.getEntity(); 
         
		int status = response.getStatusLine().getStatusCode();

		// we assume that the response body contains the error message
		if (status != HttpStatus.SC_OK) {
			ByteArrayOutputStream ostream = new ByteArrayOutputStream();
			entity.writeTo(ostream);
			
			RWHtmlLog.e(TAG, "Error status code = " + status, null);
			RWHtmlLog.e(TAG, ostream.toString(), null);
				
			throw new Exception(HTTP_POST_FAILED + status);
		} else {
			InputStream content = response.getEntity().getContent();
			// <consume response>
			
			BufferedReader reader = new BufferedReader (new InputStreamReader(content));
			String line;
			
			while ((line = reader.readLine())!=null)
				sbResponse.append(line);
			
			content.close(); // this will also close the connection
			
			return sbResponse.toString();
		}
	}
	
	
	public static String uploadFile(String page, Properties properties, String fileParam, String file) throws Exception
	{
		if (D) { RWHtmlLog.i(TAG, "Starting upload of file: " + file, null); }

		HttpParams httpParams = new BasicHttpParams();
		HttpConnectionParams.setConnectionTimeout(httpParams, CONNECTION_TIMEOUT_MSEC);
		HttpConnectionParams.setSoTimeout(httpParams, CONNECTION_TIMEOUT_MSEC); 
		
		HttpClient httpClient = new DefaultHttpClient(httpParams);

		HttpPost request = new HttpPost(page);
		MultipartEntity entity = new MultipartEntity();
			
		Iterator<Map.Entry<Object,Object>> i = properties.entrySet().iterator();
		while (i.hasNext())
		{
		       Map.Entry<Object,Object> entry = (Map.Entry<Object,Object>) i.next();
		       String key = (String) entry.getKey();
		       String val = (String) entry.getValue();
		       entity.addPart(key, new StringBody(val));
		       if (D) { RWHtmlLog.i(TAG, "Added StringBody multipart for: '" + key + "' = '" + val + "'", null); }
		 }

		File upload = new File(file);
		entity.addPart(fileParam, new FileBody(upload));
		if (D) {
			String msg = "Added FileBody multipart for: '" + fileParam + "' = <'" + upload.getAbsolutePath() + ", size: " + upload.length() + " bytes >'";
			RWHtmlLog.i(TAG, msg, null);
		}

		request.setEntity(entity);
		
		if (D) { RWHtmlLog.i(TAG, "Sending HTTP request...", null); }
		
		HttpResponse response = httpClient.execute(request);
		
		int st = response.getStatusLine().getStatusCode();

		if (st == HttpStatus.SC_OK) {
			StringBuffer sbResponse = new StringBuffer();
			InputStream content = response.getEntity().getContent();
			BufferedReader reader = new BufferedReader (new InputStreamReader(content));
			String line;
			while ((line = reader.readLine()) != null) {
				sbResponse.append(line);
			}
			content.close(); // this will also close the connection
			
			if (D) { 
				RWHtmlLog.i(TAG, "Upload successful (HTTP code: " + st + ")", null); 
				RWHtmlLog.i(TAG, "Server response: " + sbResponse.toString(), null);
			}
			
			return sbResponse.toString();
		} else {
			ByteArrayOutputStream ostream = new ByteArrayOutputStream();
			entity.writeTo(ostream);
			RWHtmlLog.e(TAG, "Upload failed (http code: " + st + ")", null);
			RWHtmlLog.e(TAG, "Server response: " + ostream.toString(), null);
			throw new Exception(HTTP_POST_FAILED + st);
		}
	}
}
