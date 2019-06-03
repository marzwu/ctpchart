package com.cangzhitao.menu {
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	/**
	 * 修改菜单xml文件label命令错误，增加助记键ALT+
	 * update 2011-9-29
	 *
	 * 修改了包目录，对selectFunction属性值进行了判断，如果为空字符串，则不做监听
	 * update 2011-4-9
	 *
	 * 窗口菜单工具类，支持子菜单，支持定义快捷键，支持回调函数设置。
	 * 菜单xml内容格式如下。data属性暂未使用，keyEquivalent为快捷键，selectFunction为函数名，函数名为完全限定名，函数必须是public的
	 * private var menuXML:XML =   <root>
	 *                                 <menu label="文件(F)" data="file" mnemonicIndex="3">
	 *                                     <item label="新建(N)" data="new" keyEquivalent="n" mnemonicIndex="3" selectFunction="" />
	 *                                     <item label="打开(O)" data="open" keyEquivalent="o" mnemonicIndex="3" selectFunction="" />
	 *                                     <item label="保存(S)" data="save" keyEquivalent="s" mnemonicIndex="3" selectFunction="" />
	 *                                     <item label="另存为(A)" data="save_as" keyEquivalent="S" mnemonicIndex="4" selectFunction="" />
	 *                                     <item lable="separator"/>
	 *                                     <item label="退出(X)" data="exit" keyEquivalent="x" mnemonicIndex="3" selectFunction="main.exitApp" />
	 *                                 </menu>
	 *                                 <menu label="帮助(H)" data="help" mnemonicIndex="3">
	 *                                     <item label="关于" data="about" keyEquivalent="h" selectFunction="" />
	 *                                 </menu>
	 *                             </root>
	 * cangzhitao 2011-1-15
	 * www15119258@qq.com
	 * http://cangzhitao.com
	 */
	public class MenuUtil {
		
		public function MenuUtil() {
		}
		
		//创建顶级菜单
		public static function createRootMenu(menuXML:XML):NativeMenu {
			var rootMenu:NativeMenu = new NativeMenu();
			for each(var xml:XML in menuXML["menu"]) {
				var temp:NativeMenuItem = new NativeMenuItem(xml.@label);
				if (xml.hasOwnProperty("@mnemonicIndex")) {
					temp.mnemonicIndex = xml.@mnemonicIndex;
				}
				rootMenu.addItem(temp);
				temp.submenu = createMenu(xml);
			}
			return rootMenu;
		}
		
		public static var classes:Dictionary = new Dictionary();
		
		//创建子菜单
		private static function createMenu(menuXML:XML):NativeMenu {
			var subMenu:NativeMenu = new NativeMenu();
			for each(var xml:XML in menuXML["item"]) {
				var temp:NativeMenuItem;
				if (xml.@lable == "separator") {
					temp = subMenu.addItem(new NativeMenuItem("", true));
				} else {
					temp = subMenu.addItem(new NativeMenuItem(xml.@label));
				}
				//添加快捷键
				if (xml.hasOwnProperty("@keyEquivalent")) {
					temp.keyEquivalent = xml.@keyEquivalent;
				}
				if (xml.hasOwnProperty("@mnemonicIndex")) {
					temp.mnemonicIndex = xml.@mnemonicIndex;
				}
				if (xml.hasOwnProperty("@data")) {
					temp.data = xml.@data;
				}
				//添加回调函数
				if (xml.hasOwnProperty("@selectFunction") && xml.@selectFunction != "") {
					var functionArray:Array = String(xml.@selectFunction).split(".");
//					var objectClass:Class = getDefinitionByName(functionArray[0]) as Class;
//					var object:Object = new objectClass();
					//必须把所调函数所在的类添加进classes字典里
					var object:Object = classes[functionArray[0]];
					temp.addEventListener(Event.SELECT, object[functionArray[1]]);
				}
				//迭代添加子菜单
				if (XMLList(xml["item"]).length() > 0) {
					temp.submenu = createMenu(xml);
				}
			}
			return subMenu;
		}
	}
}