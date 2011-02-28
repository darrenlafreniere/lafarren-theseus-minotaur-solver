//
// Copyright 2010, Darren Lafreniere
// <http://www.lafarren.com/theseus-minotaur-solver/>
// 
// This file is part of lafarren.com's Theseus and Minotaur Maze Solver,
// or tmmaze-solver.
// 
// tmmaze-solver is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// tmmaze-solver is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with tmmaze-solver, named License.txt. If not, see
// <http://www.gnu.org/licenses/>.
//
package com.lafarren.tmmaze.ui
{
	import flash.display.DisplayObject;
	import mx.containers.TitleWindow;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	/**
	 * PopUp base class. Manages its own opening, closing, parent attachment,
	 * centering, and focus stack management.
	 */
	public class PopUp extends TitleWindow
	{
		private var m_attachTo:DisplayObject;
		private var m_autoCenter:Boolean;
		private var m_autoFocusStack:Boolean;
		private var m_autoFocusStackExclusive:Boolean;
		
		private var m_modal:Boolean;
		
		public function PopUp()
		{
			super();
			
			this.showCloseButton = true;
			addEventListener(CloseEvent.CLOSE, onClose);
			
			this.attachTo = null;
			this.autoCenter = true;
			this.autoFocusStack = true;
			this.autoFocusStackExclusive = false;
		}
		
		/**
		 * The display object that the PopUp gets attached to on open. Once open
		 * the attachTo object becomes this PopUp's parent.
		 * 
		 * If the PopUp is already open and attachTo is changed to a different
		 * object, the PopUp will close and re-open itself.
		 * 
		 * Defaults to Application.application.
		 */
		public function get attachTo():DisplayObject
		{
			return m_attachTo;
		}
		
		public function set attachTo(attachTo:DisplayObject):void
		{
			if (!m_attachTo || m_attachTo != attachTo)
			{
				m_attachTo = attachTo ? attachTo : DisplayObject(Application.application);
				if (this.opened && this.parent != m_attachTo)
				{
					var modal:Boolean = this.modal;
					close();
					open(modal);
				}
			}
		}
		
		/**
		 * If true, the PopUp will be auto centered over its parent.
		 * 
		 * Defaults to true.
		 */
		public function get autoCenter():Boolean
		{
			return m_autoCenter;
		}
		
		public function set autoCenter(autoCenter:Boolean):void
		{
			if (m_autoCenter != autoCenter)
			{
				m_autoCenter = autoCenter;
				if (this.opened && this.autoCenter)
				{
					center();
				}
			}
		}
		
		/**
		 * If true, the PopUp will be auto push and remove itself to and from
		 * the FocusStack, along with the autoFocusStackExclusive flag.
		 * 
		 * Defaults to true.
		 * 
		 * @see FocusStack.push
		 */
		public function get autoFocusStack():Boolean
		{
			return m_autoFocusStack;
		}
		
		public function set autoFocusStack(autoFocusStack:Boolean):void
		{
			if (m_autoFocusStack != autoFocusStack)
			{
				focusStackPop();
				m_autoFocusStack = autoFocusStack;
				focusStackPush();
			}
		}
		
		/**
		 * If autoFocusStack is true, this flag will be passed along to
		 * FocusStack.push.
		 * 
		 * Defaults to false.
		 * 
		 * @see FocusStack.push
		 */
		public function get autoFocusStackExclusive():Boolean
		{
			return m_autoFocusStackExclusive;
		}
		
		public function set autoFocusStackExclusive(autoFocusStackExclusive:Boolean):void
		{
			if (m_autoFocusStackExclusive != autoFocusStackExclusive)
			{
				focusStackPop();
				m_autoFocusStackExclusive = autoFocusStackExclusive;
				focusStackPush();
			}
		}
		
		/**
		 * True if the PopUp is currently open.
		 */
		public function get opened():Boolean
		{
			return this.parent != null;
		}
		
		/**
		 * True if the PopUp is currently open and modal.
		 */
		public function get modal():Boolean
		{
			return this.opened && m_modal;
		}
		
		/**
		 * Opens this PopUp modelessly by calling open(false).
		 */
		public function openModeless():void
		{
			open(false);
		}
		
		/**
		 * Opens this PopUp modally by calling open(true).
		 */
		public function openModal():void
		{
			open(true);
		}
		
		/**
		 * Opens this PopUp.
		 * @param	modal Modal if true, modeless if false.
		 */
		public function open(modal:Boolean):void
		{
			if (this.modal != modal)
			{
				close();
			}
			
			if (this.opened)
			{
				PopUpManager.bringToFront(this);
			}
			else
			{
				m_modal = modal;
				PopUpManager.addPopUp(this, m_attachTo, m_modal);
				focusStackPush();
			}
			
			if (this.autoCenter)
			{
				center();
			}
		}
		
		/**
		 * Closes this PopUp.
		 */
		public function close():void
		{
			if (this.opened)
			{
				focusStackPop();
				PopUpManager.removePopUp(this);
			}
		}
		
		/**
		 * Centers an opened PopUp within its parent.
		 */
		public function center():void
		{
			if (this.opened)
			{
				PopUpManager.centerPopUp(this);
			}
		}
		
		private function onClose(event:CloseEvent):void
		{
			close();
		}
		
		private function focusStackPush():void
		{
			if (this.opened && this.autoFocusStack)
			{
				FocusStack.focusStack.push(this, this.autoFocusStackExclusive);
			}
		}
		
		private function focusStackPop():void
		{
			if (this.opened && this.autoFocusStack)
			{
				FocusStack.focusStack.remove(this);
			}
		}
	}
}
