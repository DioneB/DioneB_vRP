window.addEventListener("load",function(){
  errdiv = document.createElement("div");
  if(true){ //debug
    errdiv.classList.add("console");
    document.body.appendChild(errdiv);
    window.onerror = function(errorMsg, url, lineNumber, column, errorObj){
        errdiv.innerHTML += '<br />Error: ' + errorMsg + ' Script: ' + url + ' Line: ' + lineNumber
                + ' Column: ' + column + ' StackTrace: ' +  errorObj;
    }
  }

  log = function(txt)
  {
    errdiv.innerHTML += "<br />log: "+txt;
  }

  //init dynamic menu
  var dynamic_menu = new Menu();
  var wprompt = new WPrompt();
  var requestmgr = new RequestManager();
  var announcemgr = new AnnounceManager();
  var aengine = new AudioEngine();

  requestmgr.onResponse = function(id,ok){ $.post("http://vrp/request",JSON.stringify({act: "response", id: id, ok: ok})); }
  wprompt.onClose = function(){ $.post("http://vrp/prompt",JSON.stringify({act: "close", result: wprompt.result})); }
  dynamic_menu.onClose = function(){ $.post("http://vrp/menu",JSON.stringify({act: "close", id: dynamic_menu.id})); }
  dynamic_menu.onValid = function(choice,mod){ $.post("http://vrp/menu",JSON.stringify({act: "valid", id: dynamic_menu.id, choice: choice, mod: mod})); }

  //init
  $.post("http://vrp/init",""); 

  var current_menu = dynamic_menu;
  var pbars = {}
  var divs = {}

  //progress bar ticks (25fps)
  setInterval(function(){
    for(var k in pbars){
      pbars[k].frame(1/25.0*1000);
    }

  }, 1/25.0*1000);

  //MESSAGES
  window.addEventListener("message",function(evt){ //lua actions
    var data = evt.data;

    if(data.act == "cfg"){
      cfg = data.cfg
    }
    else if(data.act == "pause_change"){
      if(data.paused)
        $(document.body).hide();
      else
        $(document.body).show();
    }
    else if(data.act == "open_menu"){ //OPEN DYNAMIC MENU
      current_menu.close();
      dynamic_menu.open(data.menudata.name,data.menudata.choices);
      dynamic_menu.id = data.menudata.id;

      //customize menu
      var css = data.menudata.css
      if(css.top)
        dynamic_menu.div.style.top = css.top;
      if(css.header_color)
        dynamic_menu.div_header.style.backgroundColor = css.header_color;

      current_menu = dynamic_menu;
    }
    else if(data.act == "close_menu"){ //CLOSE MENU
      current_menu.close();
    }
    // PROGRESS BAR
    else if(data.act == "set_pbar"){
      var pbar = pbars[data.pbar.name];
      if(pbar)
        pbar.removeDom();

      pbars[data.pbar.name] = new ProgressBar(data.pbar);
      pbars[data.pbar.name].addDom();
    }
    else if(data.act == "set_pbar_val"){
      var pbar = pbars[data.name];
      if(pbar)
        pbar.setValue(data.value);
    }
    else if(data.act == "set_pbar_text"){
      var pbar = pbars[data.name];
      if(pbar)
        pbar.setText(data.text);
    }
    else if(data.act == "remove_pbar"){
      var pbar = pbars[data.name]
      if(pbar){
        pbar.removeDom();
        delete pbars[data.name];
      }
    }
    // PROMPT 
    else if(data.act == "prompt"){
      wprompt.open(data.title,data.text);
    }
    // REQUEST
    else if(data.act == "request"){
      requestmgr.addRequest(data.id,data.text,data.time);
    }
    // ANNOUNCE
    else if(data.act == "announce"){
      announcemgr.addAnnounce(data.background,data.content);
    }
    // DIV
    else if(data.act == "set_div"){
      var div = divs[data.name];
      if(div)
        div.removeDom();

      divs[data.name] = new Div(data)
      divs[data.name].addDom();
    }
    else if(data.act == "set_div_css"){
      var div = divs[data.name];
      if(div)
        div.setCss(data.css);
    }
    else if(data.act == "set_div_content"){
      var div = divs[data.name];
      if(div)
        div.setContent(data.content);
    }
    else if(data.act == "div_execjs"){
      var div = divs[data.name];
      if(div)
        div.executeJS(data.js);
    }
    else if(data.act == "remove_div"){
      var div = divs[data.name];
      if(div)
        div.removeDom();

      delete divs[data.name];
    }
    // AUDIO
    else if(data.act == "play_audio_source")
      aengine.playAudioSource(data);
    else if(data.act == "set_audio_source")
      aengine.setAudioSource(data);
    else if(data.act == "remove_audio_source")
      aengine.removeAudioSource(data);
    else if(data.act == "audio_listener")
      aengine.setListenerData(data);
    //VoIP
    else if(data.act == "connect_voice")
      aengine.connectVoice(data);
    else if(data.act == "disconnect_voice")
      aengine.disconnectVoice(data);
    else if(data.act == "disconnect_voice")
      aengine.disconnectVoice(data);
    else if(data.act == "voice_peer_signal")
      aengine.voicePeerSignal(data);
    else if(data.act == "set_voice_state")
      aengine.setVoiceState(data);
    else if(data.act == "configure_voice")
      aengine.configureVoice(data);
    else if(data.act == "set_peer_configuration")
      aengine.setPeerConfiguration(data);
    else if(data.act == "set_player_positions")
      aengine.setPlayerPositions(data);
    // CONTROLS
    else if(data.act == "event"){ //EVENTS
      if(data.event == "UP"){
        if(!wprompt.opened)
          current_menu.moveUp();
      }
      else if(data.event == "DOWN"){
        if(!wprompt.opened)
          current_menu.moveDown();
      }
      else if(data.event == "LEFT"){
        if(!wprompt.opened)
          current_menu.valid(-1);
      }
      else if(data.event == "RIGHT"){
        if(!wprompt.opened)
          current_menu.valid(1);
      }
      else if(data.event == "SELECT"){
        if(!wprompt.opened)
          current_menu.valid(0);
      }
      else if(data.event == "CANCEL"){
        if(wprompt.opened)
          wprompt.close();
        else
          current_menu.close();

      }
      else if(data.event == "F5"){
        requestmgr.respond(true);
      }
      else if(data.event == "F6"){
        requestmgr.respond(false);
      }
    }
  });
});
