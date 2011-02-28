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
	import flash.display.InteractiveObject;
	import flash.events.FocusEvent;
	import mx.core.Application;
	
	/**
	 * Manages a stack of focus targets. A target can be pushed onto the
	 * stack, which will restrict keyboard focus to it and, if its exclusive
	 * flag is false, to any child component of it. If its exclusive flag is
	 * true, only the target is allowed to have focus, until it is popped, or
	 * another target is pushed onto the stack. When a target is popped, the
	 * target below it will receive focus according to its exclusivity rule.
	 */
	public class FocusStack
	{
		// Singleton instance.
		private static var m_focusStack:FocusStack;
		
		private const m_items:Vector.<Item> = new Vector.<Item>();
		private var m_focusChangeCount:int;
		
		public function FocusStack()
		{
			if (m_focusStack)
			{
				throw new Error("The FocusStack singleton has already been created!");
			}
			
			registerForFocusEvents();
		}
		
		public static function get focusStack():FocusStack
		{
			if (!m_focusStack)
			{
				m_focusStack = new FocusStack();
			}
			
			return m_focusStack;
		}
		
		/**
		 * Pushes a new target and its exclusivity.
		 * @param	target The target for which focus is allowed for it and, if exclusive is false, its children.
		 * 			Pushing a null target to the top will disable the stack's focus adjustment.
		 * @param	exclusive If true, only the target can receive focus, otherwise its children may as well.
		 */
		public function push(target:InteractiveObject, exclusive:Boolean):void
		{
			m_items.push(new Item(target, exclusive));
			adjustFocus();
		}
		
		/**
		 * Pops the current target from the stack and returns it.
		 * @return The target that was popped from the stack.
		 */
		public function pop():InteractiveObject
		{
			var item:Item = this.itemTop;
			if (item)
			{
				remove(item.target);
			}
			else
			{
				throw new Error("pop without a matching push");
			}
			
			return item ? item.target : null;
		}
		
		/**
		 * Removes the top-most stack item found for the specified target.
		 * @param	target The target for which to remove the top-most item for.
		 * @return	True if the target was found in the stack, false otherwise.
		 */
		public function remove(target:InteractiveObject):Boolean
		{
			var result:Boolean = false;
			for (var i:int = m_items.length; --i >= 0; )
			{
				if (m_items[i].target == target)
				{
					m_items.splice(i, 1);
					result = true;
					break;
				}
			}
			
			adjustFocus();
			return result;
		}
		
		private function registerForFocusEvents():void
		{
			var app:Application = Application.application as Application;
			if (app && app.stage)
			{
				app.stage.addEventListener(FocusEvent.FOCUS_IN, onFocusChange);
				app.stage.addEventListener(FocusEvent.FOCUS_OUT, onFocusChange);
			}
			else
			{
				app.callLater(registerForFocusEvents);
			}
		}
		
		private function onFocusChange(event:FocusEvent):void
		{
			// Accumulate focus changes until the next update, and do a single
			// adjustment later.
			++m_focusChangeCount;
			Application.application.callLater(handleFocusChanges);
		}
		
		private function handleFocusChanges():void
		{
			if (m_focusChangeCount > 0)
			{
				m_focusChangeCount = 0;
				adjustFocus();
			}
		}
		
		private function adjustFocus():void
		{
			var app:Application = Application.application as Application;
			if (app && app.stage)
			{
				var item:Item = this.itemTop;
				if (item && item.target)
				{
					if (item.exclusive)
					{
						if (app.stage.focus != item.target)
						{
							app.stage.focus = item.target;
						}
					}
					else
					{
						var isDescendant:Boolean = false;
						{
							var current:InteractiveObject = Application.application.stage.focus;
							while (!isDescendant && current)
							{
								isDescendant = (current == item.target);
								current = current.parent;
							}
						}
						
						if (!isDescendant)
						{
							app.stage.focus = item.target;
						}
					}
				}
			}
		}
		
		private function get itemTop():Item
		{
			return (m_items.length > 0) ? m_items[m_items.length - 1] : null;
		}
	}
}

import flash.display.InteractiveObject;

// Internal stack item class.
internal class Item
{
	public var target:InteractiveObject;
	public var exclusive:Boolean;
	
	public function Item(target:InteractiveObject, exclusive:Boolean)
	{
		this.target = target;
		this.exclusive = exclusive;
	}
}
