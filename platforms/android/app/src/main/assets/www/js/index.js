/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
var app = {
    // Application Constructor

    initialize: function() {
        document.addEventListener('deviceready', this.onDeviceReady.bind(this), false);
        console.log("console.log works well");
    },

    // deviceready Event Handler
    //
    // Bind any cordova events here. Common events are:
    // 'pause', 'resume', etc.
    onDeviceReady: function() {

        var pushButton = document.getElementById("pushButton");
        pushButton.addEventListener('click',function(){ popdeem.pushPopdeemHome(function() {}, function() {});}, false);

        var loginButton = document.getElementById("loginButton");
        loginButton.addEventListener('click',function(){ popdeem.enableSocialLogin(1000, function() {}, function() {});}, false);

        var tokenButton = document.getElementById("tokenButton");
        tokenButton.addEventListener('click',function(){ popdeem.deliverThirdPartyToken("francois@spoonity.com", function() {}, function() {});}, false);

        this.receivedEvent('deviceready');

        const push = PushNotification.init({
            ios: {
              alert: 'true',
              badge: true,
              sound: 'false'
            }
          });

        push.subscribe(
            'my-topic',
            () => {
              console.log('success');
            },
            e => {
              console.log('error:', e);
            }
        );

        PushNotification.hasPermission(data => {
            if (data.isEnabled) {
                navigator.notification.alert('Is Enabled', ok, 'Title', 'Button!');
            }
        });
    },

    // Update DOM on a Received Event
    receivedEvent: function(id) {
        var parentElement = document.getElementById(id);
        var listeningElement = parentElement.querySelector('.listening');
        var receivedElement = parentElement.querySelector('.received');

        listeningElement.setAttribute('style', 'display:none;');
        receivedElement.setAttribute('style', 'display:block;');

        console.log('Received Event: ' + id);
    }
};

app.initialize();
