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
	/**
	 * AS3 doesn't support enums, but this is meant to be treated as such.
	 * Defines a maze's entity types.
	 */
	public final class EntityType
	{
		// Flags
		public static const IS_AGENT:uint = (1 << 0);
		public static const IS_EXIT:uint  = (1 << 1);
		
		public static const THESEUS:EntityType = new EntityType("THESEUS", IS_AGENT);
		public static const MINOTAUR:EntityType = new EntityType("MINOTAUR", IS_AGENT);
		public static const EXIT:EntityType = new EntityType("EXIT", IS_EXIT);
		
		// Internal collection definitions
		private static const m_array:Array =
		[
			THESEUS,
			MINOTAUR,
			EXIT,
		];
		private static const m_vector:Vector.<EntityType> = Vector.<EntityType>(m_array);
		
		private static const m_agentArray:Array = m_array.filter
		(
			function callback(item:*, index:int, array:Array):Boolean
			{
				return item.isAgent;
			}
		);
		private static const m_agentVector:Vector.<EntityType> = Vector.<EntityType>(m_agentArray);
		
		// Auto-generate an ordinal for each enum instance.
		private static var m_nextOrdinal:int = 0;
		
		// Instance members
		private const m_ordinal:int = m_nextOrdinal++;
		private var m_name:String;
		private var m_flags:uint;
		
		/**
		 * AS3 doesn't allow for private constructors, but this should be considered as such.
		 */
		public function EntityType(name:String, flags:uint)
		{
			m_name = name;
			m_flags = flags;
		}
		
		/**
		 * The ordinal for this enum constant.
		 */
		public function get ordinal():int
		{
			return m_ordinal;
		}
		
		/**
		 * The name for this enum constant.
		 */
		public function get name():String
		{
			return m_name;
		}
		
		/**
		 * The flags for this enum constant.
		 */
		public function get flags():int
		{
			return m_flags;
		}
		
		/**
		 * True if this entity is an agent.
		 */
		public function get isAgent():Boolean
		{
			return (m_flags & IS_AGENT) != 0;
		}
		
		/**
		 * True if this entity is an exit position.
		 */
		public function get isExitPosition():Boolean
		{
			return (m_flags & IS_EXIT) != 0;
		}
		
		/**
		 * The number of EntityType instances.
		 */
		public static const length:int = m_array.length;
		
		/**
		 * The array of EntityType instances.
		 */
		public static function get array():Array
		{
			return m_array.concat();
		}
		
		/**
		 * The vector of EntityType instances.
		 */
		public static function get vector():Vector.<EntityType>
		{
			return m_vector.concat();
		}
		
		/**
		 * The number of isAgent EntityType instances.
		 */
		public static const agentLength:int = m_agentArray.length;
		
		/**
		 * The array of isAgent EntityType instances.
		 */
		public static function get agentArray():Array
		{
			return m_agentArray.concat();
		}
		
		/**
		 * The vector of isAgent EntityType instances.
		 */
		public static function get agentVector():Vector.<EntityType>
		{
			return m_agentVector.concat();
		}
		
		/**
		 * Returns an EntityType from its ordinal.
		 */
		public static function fromOrdinal(ordinal:int):EntityType
		{
			var v:Vector.<EntityType> = EntityType.vector;
			return (ordinal >= 0 && ordinal < v.length) ? v[ordinal] : null;
		}
	}
}
