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
package com.lafarren.tmmaze.core
{
	import flash.events.Event;
	
	/**
	 * Event class dispatched from a Game instance.
	 */
	public class GameEvent extends Event
	{
		/**
		 * Defines the value of the <code>type</code> property of the event object 
		 * for a <code>begin</code> event.
		 *
		 * <p>The properties of the event object have the following values:</p>
		 * <table class=innertable>
		 * 		<tr><th>Property</th><th>Value</th></tr>
		 * 		<tr><td>game</td><td>The Game that dispatched this event</td></tr>
		 * </table>
		 *
		 * @eventType begin
		 */
		public static const BEGIN:String = "begin";
		
		/**
		 * Defines the value of the <code>type</code> property of the event object 
		 * for a <code>end</code> event.
		 *
		 * <p>The properties of the event object have the following values:</p>
		 * <table class=innertable>
		 * 		<tr><th>Property</th><th>Value</th></tr>
		 * 		<tr><td>game</td><td>The Game that dispatched this event</td></tr>
		 * </table>
		 *
		 * @eventType end
		 */
		public static const END:String = "end";
		
		/**
		 * Defines the value of the <code>type</code> property of the event object 
		 * for a <code>copyable</code> event.
		 *
		 * <p>The properties of the event object have the following values:</p>
		 * <table class=innertable>
		 * 		<tr><th>Property</th><th>Value</th></tr>
		 * 		<tr><td>game</td><td>The Game that dispatched this event</td></tr>
		 * </table>
		 *
		 * @eventType copyable
		 */
		public static const COPYABLE:String = "copyable";
		
		private var m_game:Game;
		
		public function GameEvent(game:Game, type:String, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			m_game = game;
		}
		
		/**
		 * Constructs a new begin event.
		 */
		public static function begin(game:Game):GameEvent
		{
			return new GameEvent(game, BEGIN);
		}
		
		/**
		 * Constructs a new end event.
		 */
		public static function end(game:Game):GameEvent
		{
			return new GameEvent(game, END);
		}
		
		/**
		 * Constructs a new copyable event.
		 */
		public static function copyable(game:Game):GameEvent
		{
			return new GameEvent(game, COPYABLE);
		}
		
		/**
		 * The relevant Game for the event.
		 */
		public function get game():Game
		{
			return m_game;
		}
	}
}
