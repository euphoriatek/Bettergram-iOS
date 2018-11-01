//
//  MWFeedItem.m
//  MWFeedParser
//
//  Copyright (c) 2010 Michael Waterfall
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  1. The above copyright notice and this permission notice shall be included
//     in all copies or substantial portions of the Software.
//  
//  2. This Software cannot be used to archive or collect data such as (but not
//     limited to) that of events, news, experiences and activities, for the 
//     purpose of any concept relating to diary/journal keeping.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "MWFeedItem.h"
#import <LegacyComponents/LegacyComponents.h>


#define EXCERPT(str, len) (([str length] > len) ? [[str substringToIndex:len-1] stringByAppendingString:@"…"] : str)

@implementation MWFeedItem

@synthesize identifier, title, link, date, updated, summary, content, author, enclosures, thumbnailURL, viewsCount, feedURL, isViewed, feedTitle;

#pragma mark NSObject

- (NSString *)description {
	NSMutableString *string = [[NSMutableString alloc] initWithString:@"MWFeedItem: "];
	if (title)   [string appendFormat:@"“%@”", EXCERPT(title, 50)];
	if (date)    [string appendFormat:@" - %@", date];
	//if (link)    [string appendFormat:@" (%@)", link];
	//if (summary) [string appendFormat:@", %@", EXCERPT(summary, 50)];
	return string;
}


#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
	if ((self = [super init])) {
		identifier = [decoder decodeObjectForKey:@"identifier"];
		title = [decoder decodeObjectForKey:@"title"];
		link = [decoder decodeObjectForKey:@"link"];
		date = [decoder decodeObjectForKey:@"date"];
		updated = [decoder decodeObjectForKey:@"updated"];
		summary = [decoder decodeObjectForKey:@"summary"];
		content = [decoder decodeObjectForKey:@"content"];
		author = [decoder decodeObjectForKey:@"author"];
		enclosures = [decoder decodeObjectForKey:@"enclosures"];
        feedURL = [decoder decodeObjectForKey:@"feedURL"];
        feedTitle = [decoder decodeObjectForKey:@"feedTitle"];
        thumbnailURL = [decoder decodeObjectForKey:@"thumbnailURL"];
        viewsCount = [decoder decodeObjectForKey:@"viewsCount"];
        isViewed = [decoder decodeBoolForKey:@"isViewed"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	if (identifier) [encoder encodeObject:identifier forKey:@"identifier"];
	if (title) [encoder encodeObject:title forKey:@"title"];
	if (link) [encoder encodeObject:link forKey:@"link"];
	if (date) [encoder encodeObject:date forKey:@"date"];
	if (updated) [encoder encodeObject:updated forKey:@"updated"];
	if (summary) [encoder encodeObject:summary forKey:@"summary"];
	if (content) [encoder encodeObject:content forKey:@"content"];
	if (author) [encoder encodeObject:author forKey:@"author"];
	if (enclosures) [encoder encodeObject:enclosures forKey:@"enclosures"];
    if (feedURL) [encoder encodeObject:feedURL forKey:@"feedURL"];
    if (feedTitle) [encoder encodeObject:feedTitle forKey:@"feedTitle"];
    if (thumbnailURL) [encoder encodeObject:thumbnailURL forKey:@"thumbnailURL"];
    if (viewsCount) [encoder encodeObject:viewsCount forKey:@"viewsCount"];
    [encoder encodeBool:isViewed forKey:@"isViewed"];
}

- (void)updateWithFeedItem:(MWFeedItem *)feedItem
{
    if (![identifier isEqual:feedItem.identifier]) return;
    if (feedItem.title != nil) title = feedItem.title;
    if (feedItem.link != nil) link = feedItem.link;
    if (feedItem.date != nil) date = feedItem.date;
    if (feedItem.updated != nil) updated = feedItem.updated;
    if (feedItem.summary != nil) summary = feedItem.summary;
    if (feedItem.content != nil) content = feedItem.content;
    if (feedItem.author != nil) author = feedItem.author;
    if (feedItem.enclosures != nil) enclosures = feedItem.enclosures;
    if (feedItem.feedURL != nil) feedURL = feedItem.feedURL;
    if (feedItem.feedTitle != nil) feedTitle = feedItem.feedTitle;
    if (feedItem.thumbnailURL != nil) thumbnailURL = feedItem.thumbnailURL;
    if (feedItem.viewsCount != nil) viewsCount = feedItem.viewsCount;
}

- (BOOL)validateFilter:(NSString *)filter
{
    return
    [title validateFilter:filter] ||
    [summary validateFilter:filter] ||
    [author validateFilter:filter];
}

@end
