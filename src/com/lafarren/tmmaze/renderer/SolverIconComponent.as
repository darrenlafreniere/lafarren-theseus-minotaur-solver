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
package com.lafarren.tmmaze.renderer
{
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.controls.Image;
	
	import com.lafarren.tmmaze.core.MoveType;
	
	/**
	 * Encapsulates a component for indicating solver directions within the UI.
	 */
	public class SolverIconComponent extends UIComponent
	{
		[Embed(source="/../assets/icons/move-type-right.png")]
		private static const IconMoveTypeRight:Class;
		
		[Embed(source="/../assets/icons/move-type-skip.png")]
		private static const IconMoveTypeSkip:Class;
		
		// The minimum alpha value when strobing:
		private const STROBE_ALPHA_MIN:Number = 0.5;
		
		// The time in seconds for a strobe to go from max alpha to max alpha.
		private const STROBE_FREQUENCY_SECONDS:Number =  0.66;
		
		private var m_arrow:UIComponent;
		private var m_skip:UIComponent;
		private var m_bounds:Rectangle = new Rectangle();
		
		private var m_transitionSeconds:Number = 0.0;
		private var m_transitionStartMilliseconds:Number;
		private var m_strobe:Boolean;
		private var m_moveTypeLast:MoveType;
		private var m_moveType:MoveType;
		
		private var m_enterFrameListenerCount:int;
		
		public function SolverIconComponent()
		{
			var bitmap:Bitmap;
			var image:Image;
			
			{
				m_arrow = new UIComponent();
				m_arrow.alpha = 0.0;
				addChild(m_arrow);
				
				bitmap = new IconMoveTypeRight();
				image = new Image();
				image.source = bitmap;
				image.width = bitmap.width;
				image.height = bitmap.height;
				image.y = -(image.height / 2);
				m_arrow.width = image.width;
				m_arrow.height = image.height;
				m_arrow.addChild(image);
			}
			
			{
				m_skip = new UIComponent();
				m_skip.alpha = 0.0;
				addChild(m_skip);
				
				bitmap = new IconMoveTypeSkip();
				image = new Image();
				image.source = bitmap;
				image.width = bitmap.width;
				image.height = bitmap.height;
				image.x = -(image.width / 2);
				image.y = -(image.height / 2);
				m_skip.width = image.width;
				m_skip.height = image.height;
				m_skip.addChild(image);
			}
			
			updateImages();
		}
		
		/**
		 * The time in seconds that the component spends transitioning from
		 * one MoveType to another.
		 */
		public function get transitionSeconds():Number
		{
			return m_transitionSeconds;
		}
		
		public function set transitionSeconds(transitionSeconds:Number):void
		{
			if (m_transitionSeconds != transitionSeconds)
			{
				var transitionSecondsOld:Number = m_transitionSeconds;
				m_transitionSeconds = transitionSeconds;
				updateImages();
				
				if (transitionSecondsOld <= 0.0 && m_transitionSeconds > 0.0)
				{
					incrementEnterFrameListener();
				}
				else if (transitionSecondsOld > 0.0 && m_transitionSeconds <= 0.0)
				{
					decrementEnterFrameListener();
				}
			}
		}
		
		/**
		 * If true, the icon's alpha strobes at a fixed rate, and is combined
		 * with any manually set alpha on the component.
		 */
		public function get strobe():Boolean
		{
			return m_strobe;
		}
		
		public function set strobe(strobe:Boolean):void
		{
			if (m_strobe != strobe)
			{
				m_strobe = strobe;
				updateImages();
				
				if (m_strobe)
				{
					incrementEnterFrameListener();
				}
				else
				{
					decrementEnterFrameListener();
				}
			}
		}
		
		/*
		 * The MoveType currently displayed by the component.
		 */
		public function get moveType():MoveType
		{
			return m_moveType;
		}
		
		public function set moveType(moveType:MoveType):void
		{
			if (m_moveType != moveType)
			{
				m_transitionStartMilliseconds = getTimer();
				m_moveTypeLast = m_moveType;
				m_moveType = moveType;
				updateImages();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public override function get width():Number
		{
			return m_bounds.width;
		}
		
		/**
		 * @inheritDoc
		 */
		public override function get height():Number
		{
			return m_bounds.height;
		}
		
		/**
		 * @inheritDoc
		 */
		public override function get minWidth():Number
		{
			return Math.min(m_arrow.width, m_skip.width);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function get minHeight():Number
		{
			return Math.min(m_arrow.height, m_skip.height);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function get maxWidth():Number
		{
			return Math.max(m_arrow.width, m_skip.width);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function get maxHeight():Number
		{
			return Math.max(m_arrow.height, m_skip.height);
		}
		
		/**
		 * The local space bounds of the icon, averaged by the subcomponent alphas.
		 */
		public function get bounds():Rectangle
		{
			return m_bounds.clone();
		}
		
		/**
		 * Returns the arrow's degree rotation for the specified moveType.
		 * @param	moveType The moveType to get the arrow's degree rotation for.
		 * @return	the arrow's degree rotation for the specified moveType.
		 */
		public static function getArrowDegrees(moveType:MoveType):Number
		{
			var result:Number = 0;
			switch (moveType)
			{
				case MoveType.RIGHT:
					result = 0;
				break;
				
				case MoveType.DOWN:
					result = 90;
				break;
				
				case MoveType.LEFT:
					result = 180;
				break;
				
				case MoveType.UP:
					result = 270;
				break;
			}
			
			return result;
		}
		
		private function incrementEnterFrameListener():void
		{
			if (++m_enterFrameListenerCount == 1)
			{
				Application.application.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}
		
		private function decrementEnterFrameListener():void
		{
			--m_enterFrameListenerCount;
			if (m_enterFrameListenerCount < 0)
			{
				throw new Error("decrementEnterFrameListener called without a matching incrementEnterFrameListener");
			}
			else if (m_enterFrameListenerCount == 0)
			{
				Application.application.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}
		
		private function onEnterFrame(event:Event):void
		{
			updateImages();
		}
		
		private function updateImages():void
		{
			var currentMilliseconds:int = getTimer();
			
			if (m_moveTypeLast != m_moveType)
			{
				var deltaSeconds:Number = (currentMilliseconds - m_transitionStartMilliseconds) / 1000.0;
				var alpha:Number = (m_transitionSeconds > 0.0) ? (deltaSeconds / m_transitionSeconds) : 1.0;
				var isTransitionComplete:Boolean = (alpha >= 1.0);
				if (isTransitionComplete)
				{
					alpha = 1.0;
				}
				
				var wasArrow:Boolean = (m_moveTypeLast && m_moveTypeLast != MoveType.SKIP);
				var isArrow:Boolean = (m_moveType && m_moveType != MoveType.SKIP);
				
				if (!wasArrow && isArrow)
				{
					// Fading in arrow
					m_arrow.rotation = getArrowDegrees(m_moveType);
					m_arrow.alpha = alpha;
				}
				else if (wasArrow && !isArrow)
				{
					// Fading out arrow
					m_arrow.alpha = 1.0 - alpha;
				}
				else
				{
					// Rotating arrow
					// Compare the positive and negative angle difference to
					// find the shortest delta angle.
					var fromAngle:Number = getArrowDegrees(m_moveTypeLast);
					var toAngle:Number = getArrowDegrees(m_moveType);
					
					var base:Number = (fromAngle > toAngle) ? 360 : 0.0;
					var positiveDelta:Number = base + toAngle - fromAngle;
					var negativeDelta:Number = -(360 - positiveDelta);
					var deltaAngle:Number = (positiveDelta < -negativeDelta) ? positiveDelta : negativeDelta;
					
					m_arrow.rotation = fromAngle + (deltaAngle * alpha);
				}
				
				if (m_moveType == MoveType.SKIP)
				{
					// Fading in skip
					m_skip.alpha = alpha;
				}
				else if (m_moveTypeLast == MoveType.SKIP)
				{
					// Fading out skip
					m_skip.alpha = 1.0 - alpha;
				}
				
				if (isTransitionComplete)
				{
					m_moveTypeLast = m_moveType;
				}
			}
			
			// Strobe the icon if enabled.
			{
				// This component's alpha is reserved for use by outside
				// code. The m_arrow and m_skip alphas are reserved for
				// internal transition fading. For strobing, adjust the
				// alphas of the m_arrow and m_skip child images.
				//
				// Strobe along a sin wave, translated between STROBE_ALPHA_MIN and 1.
				var strobeAlpha:Number = 1.0;
				if (m_strobe)
				{
					var sin:Number = Math.sin(2.0 * Math.PI * (currentMilliseconds / 1000.0) / STROBE_FREQUENCY_SECONDS);
					strobeAlpha = ((sin + 1.0) / 2.0) * (1.0 - STROBE_ALPHA_MIN) + STROBE_ALPHA_MIN;
				}
				
				Vector.<UIComponent>([m_arrow, m_skip]).forEach
				(
					function(component:UIComponent, index:int, vector:Vector.<UIComponent>):void
					{
						for (var i:int = 0; i < component.numChildren; ++i)
						{
							component.getChildAt(i).alpha = strobeAlpha;
						}
					}
				);
			}
			
			// Update bounds
			{
				var arrowBounds:Rectangle = m_arrow.getBounds(this);
				var skipBounds:Rectangle = m_skip.getBounds(this);
				m_bounds.left = (arrowBounds.left * m_arrow.alpha) + (skipBounds.left * m_skip.alpha);
				m_bounds.top = (arrowBounds.top * m_arrow.alpha) + (skipBounds.top * m_skip.alpha);
				m_bounds.right = (arrowBounds.right * m_arrow.alpha) + (skipBounds.right * m_skip.alpha);
				m_bounds.bottom = (arrowBounds.bottom * m_arrow.alpha) + (skipBounds.bottom * m_skip.alpha);
			}
		}
	}
}
