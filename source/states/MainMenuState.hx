package states;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;
	var allowMouse:Bool = true; //Turn this off to block mouse movement in menus

	var menuItems:FlxTypedGroup<FlxText>;

	public var BG2:FlxSprite; 
	public var ajedrez:FlxBackdrop;
	public var selectedImage:FlxSprite;

	public var logolol:FlxSprite; 

	//Centered/Text options
	var optionShit:Array<String> = [
		//'STORY MODE',
		'FREEPLAY',
		#if MODS_ALLOWED 'MODS', #end
		#if ACHIEVEMENTS_ALLOWED 'AWARDS', #end
		'CREDITS',
		'OPTIONS',
		'???'
	];

	static var showOutdatedWarning:Bool = true;
	public function loadButtons(type:String) {
		selectedImage = new FlxSprite(0, 0);
	  
		switch (type) {
			case "bg":
				var list:Array<String> = ["1", "2", "3", "4"];
				var suffix:String = "_" + list[FlxG.random.int(0, list.length - 1)];
				selectedImage.loadGraphic(Paths.image('mainmenu/' + type.toUpperCase() + suffix));
		}
	
		selectedImage.setGraphicSize(FlxG.width, FlxG.height);
		selectedImage.scrollFactor.set(0, 0);
		selectedImage.updateHitbox();
		add(selectedImage);
	}
	override function create()
	{
		super.create();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;
		loadButtons("bg");
	
		ajedrez = new FlxBackdrop(FlxGridOverlay.createGrid(30, 30, FlxG.width, FlxG.height, true, FlxColor.BLACK, FlxColor.WHITE));
        ajedrez.scale.set(3, 3);
        ajedrez.alpha = 0.1;
        ajedrez.velocity.set(Conductor.crochet);
		add(ajedrez);

		BG2 = new FlxSprite().loadGraphic(Paths.image('mainmenu/BG2')); 
		BG2.setGraphicSize(FlxG.width, FlxG.height);
		BG2.scrollFactor.set(0, 0);
		BG2.updateHitbox();
		add(BG2);

		logolol = new FlxSprite();
		logolol.frames = Paths.getSparrowAtlas('title/logoBumpin');
		logolol.animation.addByPrefix("logo bumpin", "logo bumpin", 24, true);
		logolol.animation.play("logo bumpin");
		logolol.scrollFactor.set(0, 0);
		logolol.setGraphicSize(Std.int(logolol.width * 0.6));
		logolol.updateHitbox();
		logolol.x = 100;  
		logolol.y = 100;
		
		add(logolol);

		for (y in [0, FlxG.height - 50]) {
			var b = new FlxSprite(0, y).makeGraphic(FlxG.width, 50, 0xFF000000);
			b.scrollFactor.set();
			add(b);
		}


		menuItems = new FlxTypedGroup<FlxText>();
		add(menuItems);


		for (i in 0...optionShit.length)
		{
			var option = optionShit[i];
			var posX = 800 - (i * 30);
			var posY = 80 + (i * 90);
			var extraOffset = switch (option)
			{
				case "???": 100;
				case "MODS": 50;
				default: 0;
			}
			var item = createMenuItem(option, posX + 100 + extraOffset, posY);
			menuItems.add(item);
		}
		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		#if CHECK_FOR_UPDATES
		if (showOutdatedWarning && ClientPrefs.data.checkForUpdates && substates.OutdatedSubState.updateVersion != psychEngineVersion) {
			persistentUpdate = false;
			showOutdatedWarning = false;
			openSubState(new substates.OutdatedSubState());
		}
		#end
	}

	function createMenuItem(text:String, x:Float, y:Float):FlxText
	{
		var menuText = new FlxText(x, y, 0, text, 48);
		menuText.setFormat(Paths.font("funkin.ttf"), 72, FlxColor.BLACK, LEFT);
		menuText.borderStyle = FlxTextBorderStyle.OUTLINE;
		menuText.borderColor = FlxColor.WHITE;
		menuText.borderSize = 2;
		menuText.scrollFactor.set();
		menuText.ID = menuItems.length;
		menuItems.add(menuText);
		return menuText;
	}

	var selectedSomethin:Bool = false;

	var timeNotMoving:Float = 0;
	override function update(elapsed:Float)
{

	if (FlxG.sound.music.volume < 0.8)
		FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

	if (!selectedSomethin)
	{
		if (controls.UI_UP_P)
			changeItem(-1);

		if (controls.UI_DOWN_P)
			changeItem(1);

		if (allowMouse && ((FlxG.mouse.deltaScreenX != 0 && FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed))
		{
			FlxG.mouse.visible = true;
			timeNotMoving = 0;

			var dist:Float = -1;
			var distItem:Int = -1;

			for (i in 0...optionShit.length)
			{
				var memb:FlxText = menuItems.members[i];
				if (FlxG.mouse.overlaps(memb))
				{
					var distance:Float = Math.sqrt(Math.pow(memb.getGraphicMidpoint().x - FlxG.mouse.screenX, 2) + Math.pow(memb.getGraphicMidpoint().y - FlxG.mouse.screenY, 2));
					if (dist < 0 || distance < dist)
					{
						dist = distance;
						distItem = i;
					}
				}
			}

			if (distItem != -1 && curSelected != distItem)
			{
				curSelected = distItem;
				changeItem();
			}
		}
		else
		{
			timeNotMoving += elapsed;
			if (timeNotMoving > 2)
				FlxG.mouse.visible = false;
		}

		if (controls.BACK)
		{
			selectedSomethin = true;
			FlxG.mouse.visible = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new TitleState());
		}

		for (memb in menuItems)
			{
				var targetScale = (memb.ID == curSelected) ? 1.2 : 1.0;
				var targetAlpha = (memb.ID == curSelected) ? 1.0 : 0.5;

				memb.scale.x += (targetScale - memb.scale.x) * 0.1;
				memb.scale.y += (targetScale - memb.scale.y) * 0.1;
				memb.alpha += (targetAlpha - memb.alpha) * 0.1;
		}
		if (controls.ACCEPT || (FlxG.mouse.justPressed && allowMouse))
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			selectedSomethin = true;
			FlxG.mouse.visible = false;

			var item:FlxText = menuItems.members[curSelected];
			var option:String = optionShit[curSelected];

			FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker)
			{
				switch (option)
				{
					case 'STORY MODE':
						MusicBeatState.switchState(new StoryMenuState());
					case 'FREEPLAY':
						MusicBeatState.switchState(new FreeplayState());

					#if MODS_ALLOWED
					case 'MODS':
						MusicBeatState.switchState(new ModsMenuState());
					#end

					#if ACHIEVEMENTS_ALLOWED
					case 'AWARDS':
						MusicBeatState.switchState(new AchievementsMenuState());
					#end

					case 'CREDITS':
						MusicBeatState.switchState(new CreditsState());

					case 'OPTIONS':
						MusicBeatState.switchState(new OptionsState());
						OptionsState.onPlayState = false;
						if (PlayState.SONG != null)
						{
							PlayState.SONG.arrowSkin = null;
							PlayState.SONG.splashSkin = null;
							PlayState.stageUI = 'normal';
						}

					case 'DONATE':
						CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
						selectedSomethin = false;
						item.visible = true;
					case '???':
						trace('Menu Item ${option} doesn\'t do anything');
					default:
						trace('Menu Item ${option} doesn\'t do anything');
						selectedSomethin = false;
						item.visible = true;
				}
			});

			for (memb in menuItems)
			{
				if (memb == item)
					continue;
				FlxTween.tween(memb, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
			}

			

		}

		#if desktop
		if (controls.justPressed('debug_1'))
		{
			selectedSomethin = true;
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new MasterEditorMenu());
		}
		#end
	}

	super.update(elapsed);
}
	function changeItem(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));
		for (item in menuItems)
		{
			item.centerOffsets();
		}
		var selectedItem:FlxText = menuItems.members[curSelected];
		selectedItem.centerOffsets();
	}

}
